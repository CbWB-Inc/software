#pragma once
#include <stdint.h>
#include <stddef.h>
#include "log.h"

#define PAGE_SIZE 4096
#define PML4_INDEX(va) (((va) >> 39) & 0x1FF)
#define PDP_INDEX(va)  (((va) >> 30) & 0x1FF)
#define PD_INDEX(va)   (((va) >> 21) & 0x1FF)
#define PT_INDEX(va)   (((va) >> 12) & 0x1FF)
#define PAGE_OFFSET(va) ((va) & 0xFFF)

#define PAGE_PRESENT 0x001
#define PAGE_RW      0x002
#define PAGE_USER    0x004
#define PAGE_PWT        0x8 
#define PAGE_PCD        0x10 
#define PAGE_ACCESSED   0x20
#define PAGE_DIRTY      0x40
#define false FALSE
#define true TRUE
#define bool BOOLEAN

typedef uint64_t pte_t;

void* memset(void *s, int c, size_t n);
void* alloc_sys_page();
void* alloc_page() ;
void* alloc_pages(uint32_t num_pages);
void map_page(uintptr_t phys_addr, uintptr_t virt_addr);
uint64_t* map_page_raw(uintptr_t phys_addr, uintptr_t virt_addr);
int is_mapped(uint64_t vaddr);
void unmap_page(uint64_t virt_addr);
int virt_to_phys(uintptr_t virt_addr);
pte_t* phys_to_virt(uint64_t phys);

void pcfb(char c, uint32_t x, uint32_t y, uint32_t color);
void psfb(char* s, uint32_t x, uint32_t y, uint32_t color);
void phfb(uint64_t v, uint32_t x, uint32_t y, uint32_t color);
void ph2fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color);
void ph4fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color);
void ph8fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color);
void rectfb(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color);
void pdfb(uint64_t v, uint32_t x, uint32_t y, uint32_t color);

