#include <stdint.h>
#include <stddef.h>
#include <efi.h>
#include <efilib.h>
#include "log.h"

#define PAGE_SIZE 4096

#define PAGE_PRESENT 0x001
#define PAGE_RW      0x002
#define PAGE_USER    0x004
#define PAGE_PWT        0x8 
#define PAGE_PCD        0x10 
#define PAGE_ACCESSED   0x20
#define PAGE_DIRTY      0x40

#define PML4_INDEX(va) (((va) >> 39) & 0x1FF)
#define PDPT_INDEX(va) (((va) >> 30) & 0x1FF)
#define PD_INDEX(va)   (((va) >> 21) & 0x1FF)
#define PT_INDEX(va)   (((va) >> 12) & 0x1FF)


typedef uint64_t pte_t;

extern uint64_t *pml4;
extern uint64_t next_free_page;
extern uint64_t max_free_page;
extern uint64_t next_sys_page;
extern uint64_t page_table_base;
extern uint32_t* fb;
extern uint32_t _c_y, _c_x, _color, _pitch;

pte_t* phys_to_virt(uint64_t phys);

void* memset(void *s, int c, size_t n) {
    uint8_t* p = (uint8_t*)s;
    
    for (size_t i = 0; i < n; i++) {
        p[i] = (unsigned char)c;
    }
    return s;
}

void* alloc_page() {

    void* addr = (void*)next_free_page;
    next_free_page += PAGE_SIZE;
    
    void* virt = phys_to_virt((uint64_t)addr);
    
    return virt;
}

void* alloc_pages(uint32_t num_pages) {
    // next_free_page = align_up(next_free_page, PAGE_SIZE);
    void* addr = (void*)next_free_page;
    next_free_page += num_pages * PAGE_SIZE;
    return addr;
}

void* alloc_sys_page() {

    void* addr = (void*)next_sys_page;
    next_sys_page += PAGE_SIZE;
    
    void* virt = phys_to_virt((uint64_t)addr);

    return virt;
}

uint64_t* map_page_raw(uintptr_t phys_addr, uintptr_t virt_addr) {

    // uint64_t* pml4 = pml4_base;

    size_t pml4_idx = (virt_addr >> 39) & 0x1FF;
    size_t pdpt_idx = (virt_addr >> 30) & 0x1FF;
    size_t pd_idx   = (virt_addr >> 21) & 0x1FF;
    size_t pt_idx   = (virt_addr >> 12) & 0x1FF;

    // --- PML4 ---
    if (!(pml4[pml4_idx] & PAGE_PRESENT)) {
        uintptr_t pdpt_phys = (uintptr_t)alloc_sys_page();
        pml4[pml4_idx] = pdpt_phys | PAGE_PRESENT | PAGE_RW | PAGE_PCD | PAGE_PWT;
        uint64_t* pdpt_virt = phys_to_virt(pdpt_phys);
        memset(pdpt_virt, 0, 0x1000);  

    }
    uint64_t* pdpt_virt = phys_to_virt(pml4[pml4_idx] & ~0xFFF);

    // --- PDPT ---
    if (!(pdpt_virt[pdpt_idx] & PAGE_PRESENT)) {
        uintptr_t pd_phys = (uintptr_t)alloc_sys_page();
        pdpt_virt[pdpt_idx] = pd_phys | PAGE_PRESENT | PAGE_RW | PAGE_PCD | PAGE_PWT;
        uint64_t* pd_virt = phys_to_virt(pd_phys);
        memset(pd_virt, 0, 0x1000);  
    }
    uint64_t* pd_virt = phys_to_virt(pdpt_virt[pdpt_idx] & ~0xFFF);

    // --- PD ---
    if (!(pd_virt[pd_idx] & PAGE_PRESENT)) {
        uintptr_t pt_phys = (uintptr_t)alloc_sys_page();
        pd_virt[pd_idx] = pt_phys | PAGE_PRESENT | PAGE_RW | PAGE_PCD | PAGE_PWT;
        uint64_t* pt_virt = phys_to_virt(pt_phys);
        memset(pt_virt, 0, 0x1000);
    }
    uint64_t* pt_virt = phys_to_virt(pd_virt[pd_idx] & ~0xFFF);

    // --- PT ---
    pt_virt[pt_idx] = phys_addr | PAGE_PRESENT | PAGE_RW;

    // TLBをフラッシュ
    asm volatile ("invlpg (%0)" :: "r" (virt_addr) : "memory");

    return ((uint64_t*)pt_virt);

}

void map_page(uintptr_t phys_addr, uintptr_t virt_addr) {

    size_t pt_idx   = (virt_addr >> 12) & 0x1FF;

    uint64_t* pt_virt = map_page_raw(phys_addr, virt_addr);

    ps("Mapped: ");
    ph(virt_addr);
    ps(" => ");
    ph(phys_addr);
    ps(" (pt["); ph(pt_idx); ps("] = "); ph(pt_virt[pt_idx]); ps(")\n");

}

int is_mapped(uint64_t vaddr) {
    uint64_t pml4_index = (vaddr >> 39) & 0x1FF;
    uint64_t pdpt_index = (vaddr >> 30) & 0x1FF;
    uint64_t pd_index   = (vaddr >> 21) & 0x1FF;
    uint64_t pt_index   = (vaddr >> 12) & 0x1FF;

    uint64_t* pdpt = (uint64_t*)(pml4[pml4_index] & ~0xFFFUL);
    if (!(pml4[pml4_index] & 1)) return FALSE;

    uint64_t* pd = (uint64_t*)(pdpt[pdpt_index] & ~0xFFFUL);
    if (!(pdpt[pdpt_index] & 1)) return FALSE;

    uint64_t* pt = (uint64_t*)(pd[pd_index] & ~0xFFFUL);
    if (!(pd[pd_index] & 1)) return FALSE;

    uint64_t entry = pt[pt_index];
    return (entry & 1) != 0;
}

void unmap_page(uint64_t virt_addr) {
    uint64_t* pdpt, *pd, *pt;

    uint64_t pml4e = pml4[PML4_INDEX(virt_addr)];
    if (!(pml4e & PAGE_PRESENT)) return;
    pdpt = (uint64_t*)((pml4e & ~0xFFFUL)); // phys_to_virt するならここで

    uint64_t pdpte = pdpt[PDPT_INDEX(virt_addr)];
    if (!(pdpte & PAGE_PRESENT)) return;
    pd = (uint64_t*)((pdpte & ~0xFFFUL));

    uint64_t pde = pd[PD_INDEX(virt_addr)];
    if (!(pde & PAGE_PRESENT)) return;
    pt = (uint64_t*)((pde & ~0xFFFUL));

    // ページを無効化
    pt[PT_INDEX(virt_addr)] = 0;

    // TLBフラッシュ
    asm volatile("invlpg (%0)" :: "r" (virt_addr) : "memory");
}

uintptr_t virt_to_phys(uintptr_t virt_addr) {
    //return virt_addr - KERNEL_BASE;
    return virt_addr;
}

pte_t* phys_to_virt(uint64_t phys) {
    
    //return (pte_t*)(phys + KERNEL_BASE);  // 恒等マッピング仮定

    return (pte_t*)phys;
}

void clsfb() {
    uint32_t* row = (uint32_t*)fb;
    int width = 1280;
    int height = 800;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            row[y * _pitch + x] = _color;
        }
    }
}

char* strcpy(char* dest, const char* src) {
    char* original = dest;
    while ((*dest++ = *src++));
    return original;
}

size_t strlen(const char *s) {
    size_t i = 0;
    while (s[i]) i++;
    return i;
}