#include <stdint.h>
#include <stddef.h>
#include <efi.h>
#include <efilib.h>
#include "common.h"
#include "log.h"

static uint64_t xs_state = 88172645463325252ull; // 適当な非ゼロ初期値

uint64_t xorshift64(void) {
    xs_state ^= xs_state >> 8;
    xs_state ^= xs_state << 31;
    xs_state ^= xs_state >> 17;
    return xs_state * 2685821657736338717ull;
}

uint64_t xorshift64o(void) {
    xs_state ^= xs_state >> 12;
    xs_state ^= xs_state << 25;
    xs_state ^= xs_state >> 27;
    return xs_state * 2685821657736338717ull;
}

uint64_t xorshift64w(void) {
    xs_state ^= xs_state >> 13;
    xs_state ^= xs_state << 7;
    xs_state ^= xs_state >> 17;
    return xs_state * 2685821657736338717ull;
}


static inline int cpu_has_rdrand(void){
    uint32_t a,b,c,d;
    asm volatile("cpuid":"=a"(a),"=b"(b),"=c"(c),"=d"(d):"a"(1),"c"(0));
    return (c >> 30) & 1;  // ECX bit30
}

int rdrand64(uint64_t *out){
    if(!cpu_has_rdrand()) return 0;
    unsigned char ok;
    for(int i=0;i<10;i++){
        asm volatile("rdrand %0; setc %1"
                     : "=r"(*out), "=qm"(ok) :: "cc");
        if(ok) return 1;
        asm volatile("pause");
    }
    return 0;
}

double rdrand(void) {
    uint64_t val;
    uint8_t ok;

    __asm__ volatile (
        "rdrand %0\n\t"
        "setc %1"
        : "=r"(val), "=q"(ok)  // "r" で汎用64bitレジスタ、"q" で8bitレジスタ
        :
        : "cc"
    );

    return val;
}

double rand(void) {
    uint64_t r;
    // if (!rdrand(&r)) return -1.0;
    r = rdrand();
    // 上位53bitを使ってdoubleに正規化（IEEE754準拠）
    return (r >> 11) * (1.0 / (1ULL << 53));
}
