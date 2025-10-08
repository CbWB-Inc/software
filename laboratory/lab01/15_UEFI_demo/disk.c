#include <stdint.h>
#include <stddef.h>
#include "common.h"
#include "log.h"

// ========== HBA/MMIO 定義 ==========
#define HBA_CAP     0x00
#define HBA_GHC     0x04
#define HBA_IS      0x08
#define HBA_PI      0x0C

// 1ポートのレジスタは 0x80 幅、先頭は 0x100
#define PORT_REG(base, port, off) ((volatile uint32_t*)((uintptr_t)(base) + 0x100 + (port)*0x80 + (off)))
#define PX_CLB   0x00
#define PX_CLBU  0x04
#define PX_FB    0x08
#define PX_FBU   0x0C
#define PX_IS    0x10
#define PX_IE    0x14
#define PX_CMD   0x18
#define PX_TFD   0x20
#define PX_SIG   0x24
#define PX_SSTS  0x28
#define PX_SERR  0x30
#define PX_SACT  0x34
#define PX_CI    0x38

// CMD フィールド
#define CMD_ST  (1u<<0)   // Start
#define CMD_FRE (1u<<4)   // FIS Rx Enable
#define CMD_FR  (1u<<14)  // FIS Rx Running (RO)
#define CMD_CR  (1u<<15)  // Cmd List Running (RO)

// TFD ビット
#define TFD_BSY (1u<<7)
#define TFD_DRQ (1u<<3)

// SSTS
#define DET_MASK  0x0F
#define IPM_MASK  0xF0
#define DET_PRES  0x03     // デバイス存在+リンクup
#define IPM_ACTIVE 0x10

// FIS/ATA
#define FIS_TYPE_REG_H2D        0x27
#define ATA_CMD_READ_DMA_EXT    0x25
#define ATA_CMD_WRITE_DMA_EXT   0x35

// ========= 構造体 =========
typedef struct __attribute__((packed,aligned(1))) {
    // DW0
    uint8_t  cfl:5, a:1, w:1, p:1;
    uint8_t  r:1, b:1, c:1, rsv0:1, pmp:4;
    uint16_t prdtl;
    // DW1
    volatile uint32_t prdbc;
    // DW2-3
    uint32_t ctba, ctbau;
    // DW4-7
    uint32_t rsv1[4];
} HBA_CMD_HEADER;

typedef struct __attribute__((packed,aligned(1))) {
    uint32_t dba, dbau, rsv0;
    uint32_t dbc_ioc;     // [21:0]=byte_count-1, [31]=IOC
} HBA_PRDT;

typedef struct __attribute__((packed,aligned(128))) {
    uint8_t  cfis[64];
    uint8_t  acmd[16];
    uint8_t  rsv[48];
    HBA_PRDT prdt[1];     // 今回は1エントリのみ
} HBA_CMD_TBL;

typedef struct __attribute__((packed,aligned(256))) {
    uint8_t dsfis[0x1C];  uint8_t rsv1[0x04];
    uint8_t psfis[0x14];  uint8_t rsv2[0x0C];
    uint8_t rfis[0x14];   uint8_t rsv3[0x04];
    uint8_t sdbfis[0x08];
    uint8_t ufis[0x40];
    uint8_t rsv4[0x60];
} HBA_RCV_FIS;


// ========= 内部状態 =========
static uint64_t g_cl_phys = 0;   // Command List (1KB)
static uint64_t g_ct_phys = 0;   // Command Table (≥128B)
static uint64_t g_fis_phys = 0;  // Received FIS (256B)

// 既存環境で ABAR/port をグローバルで持っているなら流用
uint64_t abar = 0;
int      port = -1;

// ========= ユーティリティ =========
static inline void cpu_pause(void){ __asm__ volatile("pause"); }
static inline void outl(uint16_t p, uint32_t v){ __asm__ volatile("outl %0,%1"::"a"(v),"Nd"(p)); }
static inline uint32_t inl(uint16_t p){ uint32_t r; __asm__ volatile("inl %1,%0":"=a"(r):"Nd"(p)); return r; }
static inline void invlpg(void* a){ __asm__ volatile("invlpg (%0)"::"r"(a):"memory"); }

static int wait_clear_bits(volatile uint32_t* reg, uint32_t mask, int spin)
{
    while ((*reg & mask) && spin-- > 0) cpu_pause();
    return ((*reg & mask) == 0) ? 0 : -1;
}

static int wait_settle_tfd(volatile uint32_t* tfd, int spin)
{
    while (((*tfd) & (TFD_BSY|TFD_DRQ)) && spin-- > 0) cpu_pause();
    return (((*tfd) & (TFD_BSY|TFD_DRQ)) == 0) ? 0 : -1;
}

static uint32_t pci_read32(uint8_t bus, uint8_t dev, uint8_t func, uint8_t off){
    uint32_t addr = 0x80000000u | ((uint32_t)bus<<16) | ((uint32_t)dev<<11) | ((uint32_t)func<<8) | (off & 0xFC);
    outl(0xCF8, addr);
    return inl(0xCFC);
}
static uint16_t pci_read16(uint8_t bus, uint8_t dev, uint8_t func, uint8_t off){
    uint32_t v = pci_read32(bus,dev,func,off & 0xFC);
    return (v >> ((off & 2)*8)) & 0xFFFF;
}
static void pci_write16(uint8_t bus, uint8_t dev, uint8_t func, uint8_t off, uint16_t val){
    uint32_t w = pci_read32(bus,dev,func,off & 0xFC);
    uint32_t sh = (off & 2)*8;
    w &= ~(0xFFFFu << sh);
    w |= ((uint32_t)val) << sh;
    uint32_t addr = 0x80000000u | ((uint32_t)bus<<16) | ((uint32_t)dev<<11) | ((uint32_t)func<<8) | (off & 0xFC);
    outl(0xCF8, addr);
    outl(0xCFC, w);
}

void map_ahci_mmio(uint64_t abar) {
    uint64_t base = abar & ~0xFFFULL;
    // HBA全体(0x000〜0x1100程度)を安全に2ページぶん貼る
    for (uint64_t a = base; a < base + 0x2000; a += 0x1000) {
        // 可能なら PCD/PWT を立てられる版を使う（例: map_page_raw_flags）
        // なければ暫定で既存の map_page_raw でもQEMUなら動きます
        map_page_raw(a, a);
        invlpg((void*)a);
    }
}

// 簡易版：alloc_pages()で十分な連続ページを確保し、その中からアライン済みの物理先頭を切り出す
__attribute__((weak))
uint64_t alloc_phys_aligned(uint64_t size, uint64_t align)
{
    if (align < 4096) align = 4096;              // DMA用途なら最低4KiB
    uint64_t need = size + align;                // 対最悪の切り上げ分
    size_t pages = (size_t)((need + 4095) / 4096);

    uint8_t* v_base = (uint8_t*)alloc_pages(pages);   // 連続ページ確保（virt）
    uintptr_t va    = (uintptr_t)v_base;
    uintptr_t va_al = (va + (align - 1)) & ~(align - 1);

    // ★ここがミソ：仮想で合わせた先を物理化
    return virt_to_phys((uint64_t)va_al);
}

// すごく軽いチェックサム（デバッグ表示用）
static uint32_t fast_crc32(const uint8_t* p, size_t n){
    uint32_t s = 0x9E3779B9u;
    for (size_t i=0; i<n; i++) s = (s << 5) ^ (s >> 27) ^ p[i];
    return s;
}


// ========= FIS & PRDT 準備（slot 0）=========
static void prep_slot0(uint64_t abar, int port, uint64_t lba, uint64_t buf_phys, int is_write)
{
    HBA_CMD_HEADER* cl = (HBA_CMD_HEADER*)phys_to_virt(g_cl_phys);
    HBA_CMD_TBL*    ct = (HBA_CMD_TBL*)   phys_to_virt(g_ct_phys);

    memset(cl, 0, 1024);
    memset(ct, 0, sizeof(HBA_CMD_TBL));

    HBA_CMD_HEADER* h = &cl[0];
    h->cfl   = 5;                 // 20B CFIS
    h->w     = is_write ? 1 : 0;  // 書込みなら1
    h->pmp   = 0;
    h->prdtl = 1;
    h->ctba  = (uint32_t)(g_ct_phys & 0xFFFFFFFFu);
    h->ctbau = (uint32_t)(g_ct_phys >> 32);

    // PRDT: 512B, IOC=1
    ct->prdt[0].dba     = (uint32_t)(buf_phys & 0xFFFFFFFFu);
    ct->prdt[0].dbau    = (uint32_t)(buf_phys >> 32);
    ct->prdt[0].rsv0    = 0;
    ct->prdt[0].dbc_ioc = ((512 - 1) & 0x003FFFFFu) | (1u<<31);

    // CFIS (Reg H2D LBA48)
    uint8_t *f = ct->cfis;
    memset(f, 0, 64);
    f[0]  = FIS_TYPE_REG_H2D;
    f[1]  = (1u<<7); // C=1
    f[2]  = is_write ? ATA_CMD_WRITE_DMA_EXT : ATA_CMD_READ_DMA_EXT;
    f[3]  = 0; // featureL
    f[7]  = 0x40; // device (LBAモード)

    // LBA48 (low→high)
    f[4]  = (uint8_t)(lba);
    f[5]  = (uint8_t)(lba >> 8);
    f[6]  = (uint8_t)(lba >> 16);
    f[8]  = (uint8_t)(lba >> 24);
    f[9]  = (uint8_t)(lba >> 32);
    f[10] = (uint8_t)(lba >> 40);

    // sector count = 1
    f[12] = 1;
    f[13] = 0;
}

// ========= 発行→完了待ち（ポーリング）=========
static int issue_and_wait(uint64_t abar, int port)
{
    volatile uint32_t* is  = PORT_REG(abar, port, PX_IS);
    volatile uint32_t* ci  = PORT_REG(abar, port, PX_CI);
    volatile uint32_t* tfd = PORT_REG(abar, port, PX_TFD);
    volatile uint32_t* serr= PORT_REG(abar, port, PX_SERR);
    volatile uint32_t* his = (volatile uint32_t*)((uintptr_t)abar + HBA_IS);

    // 残ゴミはクリア（W1C）
    *is  = 0xFFFFFFFFu;
    *his = (1u<<port);
    *serr= 0xFFFFFFFFu;

    // 応答の準備ができるまで待つ（BSY/DRQクリア）
    if (wait_settle_tfd(tfd, 1000000) < 0) return -1;

    // スロット0発行
    *ci = 1u << 0;

    // CI bit が落ちるまで待つ（タイムアウト簡易）
    int spin = 20000000;
    while (((*ci) & 1u) && spin-- > 0) {
        // エラーを早期検出
        if (*is & (1u<<30)) return -2;  // TFES など
        cpu_pause();
    }
    if (((*ci) & 1u) != 0) return -3;   // 落ち切ってない

    // 念のため TFD の BSY/DRQ がクリアか確認
    if (wait_settle_tfd(tfd, 1000000) < 0) return -4;

    // ステータス要因のクリア（W1C）
    uint32_t v_is = *is;
    *is  = v_is;
    *his = (1u<<port);
    return 0;
}


// ========= 公開API =========
int ahci_read1(uint64_t abar, int port, uint64_t lba, uint64_t buf_phys)
{
    prep_slot0(abar, port, lba, buf_phys, 0);
    return issue_and_wait(abar, port);
}

int ahci_write1(uint64_t abar, int port, uint64_t lba, uint64_t buf_phys)
{
    prep_slot0(abar, port, lba, buf_phys, 1);
    return issue_and_wait(abar, port);
}

// ========= ポート開始/停止 =========
static void port_stop(uint64_t abar, int port)
{
    volatile uint32_t* cmd = PORT_REG(abar, port, PX_CMD);
    *cmd &= ~(CMD_ST | CMD_FRE);
    // FR/CR が下りるまで待つ
    wait_clear_bits(cmd, (CMD_FR|CMD_CR), 1000000);
}

static void port_start(uint64_t abar, int port, uint64_t cl_phys, uint64_t fis_phys)
{
    volatile uint32_t* clb  = PORT_REG(abar, port, PX_CLB);
    volatile uint32_t* clbu = PORT_REG(abar, port, PX_CLBU);
    volatile uint32_t* fb   = PORT_REG(abar, port, PX_FB);
    volatile uint32_t* fbu  = PORT_REG(abar, port, PX_FBU);
    volatile uint32_t* cmd  = PORT_REG(abar, port, PX_CMD);

    *clb  = (uint32_t)(cl_phys & 0xFFFFFFFFu);
    *clbu = (uint32_t)(cl_phys >> 32);
    *fb   = (uint32_t)(fis_phys & 0xFFFFFFFFu);
    *fbu  = (uint32_t)(fis_phys >> 32);

    // FIS受信→開始
    *cmd |= CMD_FRE;
    *cmd |= CMD_ST;
}

// ========= 初期化 =========
int ahci_init(uint64_t abar, int port)
{
    ps("AHCI CL="); ph(g_cl_phys);
    ps(" CT=");     ph(g_ct_phys);
    ps(" RFIS=");   ph(g_fis_phys); pc('\n');

    void* cl_v = phys_to_virt(g_cl_phys);
    void* ct_v = phys_to_virt(g_ct_phys);
    void* rf_v = phys_to_virt(g_fis_phys);
    ps(" virt CL="); ph((uint64_t)cl_v);
    ps(" CT=");      ph((uint64_t)ct_v);
    ps(" RFIS=");    ph((uint64_t)rf_v); pc('\n');
    
    // バッファ未確保なら確保
    if (!g_cl_phys)  g_cl_phys  = alloc_phys_aligned(1024,             1024);
    if (!g_ct_phys)  g_ct_phys  = alloc_phys_aligned(sizeof(HBA_CMD_TBL), 128);
    if (!g_fis_phys) g_fis_phys = alloc_phys_aligned(sizeof(HBA_RCV_FIS), 256);

    HBA_CMD_HEADER* cl = (HBA_CMD_HEADER*)phys_to_virt(g_cl_phys);
    HBA_CMD_TBL*    ct = (HBA_CMD_TBL*)   phys_to_virt(g_ct_phys);
    HBA_RCV_FIS*    rf = (HBA_RCV_FIS*)   phys_to_virt(g_fis_phys);
    memset(cl, 0, 1024);
    memset(ct, 0, sizeof(HBA_CMD_TBL));
    memset(rf, 0, sizeof(HBA_RCV_FIS));

    // SSTSでリンク確認
    volatile uint32_t* ssts = PORT_REG(abar, port, PX_SSTS);
    uint32_t v = *ssts;
    if ( ((v & DET_MASK) != DET_PRES) || ((v & IPM_MASK) != IPM_ACTIVE) )
        return -1; // リンク未確立

    // いったん停止 → CLB/FB 設定 → 開始
    port_stop(abar, port);
    port_start(abar, port, g_cl_phys, g_fis_phys);
    return 0;
}

// --- 追加：AHCI(HBA) を探して ABAR をセット ---
int ahci_pci_init(void){
    // bus/dev/func をざっくり総当たり（まずはバス0中心でもOK）
    for (uint8_t bus=0; bus<1; bus++){          // 必要なら 256 に
        for (uint8_t dev=0; dev<32; dev++){
            for (uint8_t func=0; func<8; func++){
                uint32_t id = pci_read32(bus,dev,func,0x00);
                if (id == 0xFFFFffffu) continue; // デバイス無し

                uint32_t classreg = pci_read32(bus,dev,func,0x08);
                uint8_t base = (classreg >> 24) & 0xFF;   // Base Class
                uint8_t sub  = (classreg >> 16) & 0xFF;   // Sub Class
                uint8_t ifc  = (classreg >>  8) & 0xFF;   // Prog IF

                // Mass Storage (0x01), SATA (0x06), AHCI (ProgIF 0x01)
                if (base==0x01 && sub==0x06 && (ifc & 0x01)){
                    uint16_t cmd = pci_read16(bus,dev,func,0x04);
                    cmd |= (1u<<1) /*MEM Space*/ | (1u<<2) /*Bus Master*/;
                    pci_write16(bus,dev,func,0x04, cmd);

                    uint32_t bar5 = pci_read32(bus,dev,func,0x24); // ABAR (BAR5)
                    uint64_t mmio = (uint64_t)(bar5 & ~0xFu);

                    extern uint64_t abar;
                    abar = mmio;
                    
                    map_ahci_mmio(abar);           // ★追加
                    
                    ps("AHCI PCI found. ABAR="); ph(abar); pc('\n');
                    return 0;
                }
            }
        }
    }
    ps("AHCI PCI not found\n");
    return -1;
}


// ========= 最初の有効ポート探索 =========
int ahci_find_first_port(uint64_t abar)
{
    volatile uint32_t* pi  = (volatile uint32_t*)((uintptr_t)abar + HBA_PI);
    uint32_t mask = *pi;
    for (int p = 0; p < 32; p++) {
        if (!(mask & (1u<<p))) continue;
        uint32_t s = *PORT_REG(abar, p, PX_SSTS);
        if ( ((s & DET_MASK) == DET_PRES) && ((s & IPM_MASK) == IPM_ACTIVE) ) {
            // SATA SIG = 0x00000101 を優先（他はATAPI等）
            if (*PORT_REG(abar, p, PX_SIG) == 0x00000101u) return p;
        }
    }
    return -1;
}


// LBA0 読み (VBR署名 0x55AA) を見る簡易テスト
int ahci_test_read_lba0(void){
    if ((int)port < 0) {
        int p = ahci_find_first_port(abar);
        if (p < 0){ ps("AHCI: no active port\n"); return -1; }
        port = (uint32_t)p;
    }
    if (ahci_init(abar, (int)port) != 0){
        ps("AHCI: init failed\n"); return -2;
    }

    uint64_t buf_phys = alloc_phys_aligned(512, 4096);
    uint8_t*  buf     = (uint8_t*)phys_to_virt(buf_phys);

    int rc = ahci_read1(abar, (int)port, /*LBA*/0, buf_phys);
    if (rc){ ps("READ LBA0 failed\n"); return rc; }

    // 末尾 0x55AA？
    uint16_t sig = (uint16_t)buf[510] | ((uint16_t)buf[511] << 8);
    ps("LBA0 sig="); ph(sig); pc('\n');
    if (sig != 0xAA55) ps("WARN: not AA55 (raw image?)\n");

    ps("LBA0 CRC="); ph(fast_crc32(buf, 512)); pc('\n');
    return 0;
}

// 1セクタ RW 検証: test_lba に書いて→読戻し→元に復旧
// ※ test_lba は安全な空き領域を指定してください（既存FSを壊さない場所）
int ahci_test_rw_once(uint64_t test_lba){
    if ((int)port < 0) {
        int p = ahci_find_first_port(abar);
        if (p < 0){ ps("AHCI: no active port\n"); return -1; }
        port = (uint32_t)p;
    }
    if (ahci_init(abar, (int)port) != 0){
        ps("AHCI: init failed\n"); return -2;
    }

    uint64_t orig_phys  = alloc_phys_aligned(512, 4096);
    uint64_t write_phys = alloc_phys_aligned(512, 4096);
    uint64_t read_phys  = alloc_phys_aligned(512, 4096);

    uint8_t* orig = (uint8_t*)phys_to_virt(orig_phys);
    uint8_t* wbuf = (uint8_t*)phys_to_virt(write_phys);
    uint8_t* rbuf = (uint8_t*)phys_to_virt(read_phys);

    // 1) 元データを保存
    int rc = ahci_read1(abar, (int)port, test_lba, orig_phys);
    if (rc){ ps("READ(orig) fail\n"); return rc; }
    uint32_t crc0 = fast_crc32(orig, 512);

    // 2) テストパターンを作成（決定論的）
    for (int i=0;i<512;i++) wbuf[i] = (uint8_t)(i ^ (test_lba & 0xFF) ^ 0x5Au);

    // 3) 書込 → 4) 読戻し
    rc = ahci_write1(abar, (int)port, test_lba, write_phys);
    if (rc){ ps("WRITE fail\n"); goto RESTORE; }

    rc = ahci_read1(abar, (int)port, test_lba, read_phys);
    if (rc){ ps("READ(back) fail\n"); goto RESTORE; }

    uint32_t crc_w = fast_crc32(wbuf, 512);
    uint32_t crc_r = fast_crc32(rbuf, 512);
    ps("CRC wr="); ph(crc_w); ps(" rd="); ph(crc_r); pc('\n');

    if (crc_w != crc_r){ ps("VERIFY MISMATCH\n"); rc = -10; }

RESTORE:
    // 5) 元に復旧（失敗しても続行）
    {
        int rc2 = ahci_write1(abar, (int)port, test_lba, orig_phys);
        if (rc2){ ps("RESTORE write fail\n"); }
        int rc3 = ahci_read1(abar, (int)port, test_lba, read_phys);
        (void)rc3;
        uint32_t crc_back = fast_crc32(rbuf, 512);
        ps("RESTORE crc0="); ph(crc0); ps(" back="); ph(crc_back); pc('\n');
        if (crc_back != crc0) ps("WARN: restore mismatch\n");
    }
    if (!rc) ps("RW test: OK\n");
    return rc;
}

void test_ahci(){
    ahci_pci_init();
    
    // LBA0 読み (VBR署名 0x55AA) を見る簡易テスト
    ahci_test_read_lba0();
    
    // 1セクタ RW 検証: test_lba に書いて→読戻し→元に復旧
    ahci_test_rw_once(0);

}