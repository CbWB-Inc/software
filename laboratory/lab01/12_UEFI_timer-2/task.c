#include <stdint.h>
#include <stddef.h>
#include "common.h"

#define TASK_SHELL_WEIGHT 3
#define TASK_NORMAL_WEIGHT 1

#define DEFAULT_TASK_WEIGHT 1     // 既定重み（idleは後で0に設定）
#define SCHED_QUANTUM_TICKS 5     // 量子（1重みあたりのtick）

extern uint32_t* fb;

static task_t* pick_next(void);

task_t *current = NULL;
task_t *runq = NULL;
task_t *termq = NULL;
task_t *idle = NULL;
task_t* exec_current = NULL;
uint64_t next_tid = 0;
uint64_t *next_rsp;
uint64_t *cur_rsp;

static int task_A_counter = 0;
static int task_B_counter = 0; 
static int task_C_counter = 0;

uint16_t current_task_id; 

task_t* spawn_subtask(task_t* domain, void (*entry_wrapper)(void), const char* name);
task_t* sub_pick_next(task_t* dom);
void restore_flags(uint64_t flags);
uint64_t save_flags_cli(void) ;
static task_t* pick_next_weighted_parent(void);
static inline task_t* owner_of(task_t* t);
static task_t* pick_next_parent_rr(void);
task_t* get_runq_entry(uint16_t id);


static inline task_t* owner_of(task_t* t){
    return (t && t->kind == TASK_SUB && t->domain) ? t->domain : t;
}


// エントリポイントも簡素化
void __attribute__((naked)) task_A_entry(void) {
    asm volatile(
        "jmp task_A"              // 直接ジャンプ（callではない）
    );
}

void __attribute__((naked)) task_B_entry(void) {
    asm volatile(
        "jmp task_B"
    );
}

void __attribute__((naked)) task_C_entry(void) {
    asm volatile(
        "jmp task_C"
    );
}

void __attribute__((naked)) idle_task_entry(void) {
    asm volatile(
        "jmp idle_task"
    );
}

// シンプルなタスクA（フレームポインタなし）
void __attribute__((optimize("-fomit-frame-pointer"))) task_A(void) {
    // ps("=== Task A started ===\n");
    for (int i = 0; i < 0xffff; i++) {
         ps("A"); ph4(i); ps(" ");

         // 短い待機
        for (volatile int j = 0; j < 500000; j++);
        
        asm volatile("sti;hlt;cli");
    }
//    ps("Task A complete\n");
    for (;;) asm volatile("sti;hlt;cli");
}

// シンプルなタスクB（フレームポインタなし）
void __attribute__((optimize("-fomit-frame-pointer"))) task_B(void) {
    // ps("=== Task B started ===\n");
    for (int i = 0; i < 0xffff; i++) {
         ps("B"); ph4(i); ps(" ");

         // 短い待機
        for (volatile int j = 0; j < 500000; j++);
        
        asm volatile("sti;hlt;cli");
    }
    // ps("Task B complete\n");
    for (;;) asm volatile("sti;hlt;cli");
}

// シンプルなタスクC（フレームポインタなし）
void __attribute__((optimize("-fomit-frame-pointer"))) task_C(void) {
//    ps("=== Task C started ===\n");
    // ps("=== Task B started ===\n");
    for (int i = 0; i < 0xffff; i++) {
         ps("C"); ph4(i); ps(" ");

         // 短い待機
        for (volatile int j = 0; j < 500000; j++);
        
        asm volatile("sti;hlt;cli");
    }
    // ps("Task C complete\n");
    for (;;) asm volatile("sti;hlt;cli");
}

// シンプルなアイドルタスク（フレームポインタなし）
void __attribute__((optimize("-fomit-frame-pointer"))) idle_task(void) {
//    ps("=== Idle task started ===\n");

    for (;;) {
        ps(".");
        
        for (volatile int i = 0; i < 100000; i++);
        
        asm volatile("hlt");
    }
}

// 修正版: x86-64 割り込みスタックフレームの正しい初期化
void* init_task_stack(void* stack_top, void* task_entry) {
//    ps("Initializing task stack:\n");
//    ps("  stack_top: "); ph((uint64_t)stack_top); ps("\n");
//    ps("  task_entry: "); ph((uint64_t)task_entry); ps("\n");
    // スタックを16バイト境界に調整
    uint64_t* sp = (uint64_t*)(((uint64_t)stack_top - 16) & ~0xF);
    
    // メモリ範囲チェック
    if (!is_mapped(sp) || !is_mapped((char*)sp - 512)) {
        ps("ERROR: Stack memory not mapped!\n");
        return NULL;
    }
    
    // **重要: x86-64 割り込みハンドラが期待する正確なスタック構造を作成**
    // 割り込みハンドラでpushされる順序: SS, RSP, RFLAGS, CS, RIP (ハードウェア)
    // その後ISRでpushされる順序: RAX, RCX, RDX, RSI, RDI, R8, R9, R10, R11, RBX, RBP, R12, R13, R14, R15
    
    // まず十分なスペースを確保
    sp -= 32;  // 安全なマージン
    
    // ISRのpop順序に合わせてスタックを構築 (逆順でpush)
    // pop順: r15, r14, r13, r12, rbp, rbx, r11, r10, r9, r8, rdi, rsi, rdx, rcx, rax, (iret: rip, cs, rflags, rsp, ss)
    // **修正: x86-64の完全な割り込みスタックフレーム**
    uint64_t task_stack_base = (uint64_t)((char*)stack_top - 1024);  // タスク用スタック領域
    
    *(--sp) = 0x0000000000000010ULL;     // SS (Data Segment - 通常は0x10)
    *(--sp) = task_stack_base;           // RSP (タスクのスタックポインタ)
    *(--sp) = 0x0000000000000202ULL;     // RFLAGS (IF=1, reserved bit=1)  
    *(--sp) = 0x0000000000000008ULL;     // CS (Code Segment)
    *(--sp) = (uint64_t)task_entry;      // RIP (実行開始アドレス)
    
    // General Purpose Registers (ISRでpushされる順序の逆)
    *(--sp) = 0x0000000000000000ULL;     // RAX
    *(--sp) = 0x0000000000000000ULL;     // RCX  
    *(--sp) = 0x0000000000000000ULL;     // RDX
    *(--sp) = 0x0000000000000000ULL;     // RSI
    *(--sp) = task_stack_base;           // **RDI: 引数として有効なアドレス**
    *(--sp) = 0x0000000000000000ULL;     // R8
    *(--sp) = 0x0000000000000000ULL;     // R9
    *(--sp) = 0x0000000000000000ULL;     // R10
    *(--sp) = 0x0000000000000000ULL;     // R11
    *(--sp) = 0x0000000000000000ULL;     // RBX
    *(--sp) = task_stack_base;           // **RBP: 有効なスタックアドレス**
    *(--sp) = 0x0000000000000000ULL;     // R12
    *(--sp) = 0x0000000000000000ULL;     // R13
    *(--sp) = 0x0000000000000000ULL;     // R14
    *(--sp) = 0x0000000000000000ULL;     // R15
    
    // **追記: スタック検証用にタスクスタック領域をチェック**
    if (!is_mapped((void*)task_stack_base) || !is_mapped((void*)(task_stack_base - 512))) {
        ps("ERROR: Task stack base not mapped: "); ph(task_stack_base); ps("\n");
        return NULL;
    }

    // 最終チェック - 割り込みスタックフレーム全体をチェック
    if (!is_mapped(sp) || !is_mapped(sp + 20)) {
        ps("ERROR: Stack frame not fully mapped!\n");
        return NULL;
    }
    
    return sp;
}


// タスク作成（簡素化版）
task_t* create_task(void* entry_func, size_t stack_pages, char* name) {
//    ps("Creating task with entry: "); ph((uint64_t)entry_func); ps("\n");

    // タスク構造体を確保
    task_t* task = alloc_pages((sizeof(task_t) + 4095) / 4096);
    if (!task) {
        ps("ERROR: Cannot allocate task struct\n");
        return NULL;
    }
    
    // スタック確保
    void* stack_mem = alloc_pages(stack_pages);
    if (!stack_mem) {
        ps("ERROR: Cannot allocate stack\n");
        return NULL;
    }
    
    // スタックトップ計算
    void* stack_top = (char*)stack_mem + stack_pages * 4096;

    // スタック初期化
    task->rsp = init_task_stack(stack_top, entry_func);
    if (!task->rsp) {
        ps("ERROR: Stack initialization failed\n");
        return NULL;
    }
    
    task->stack_base = stack_mem;
    task->stack_size = stack_pages * 4096;
    task->next = NULL;
    task->tid = next_tid++;
    task->name = name;

    return task;
}

// ランキューにタスクを追加
void add_to_runqueue(task_t* task) {
    if (!task) return;

    //    ps("Adding to runqueue: "); ph((uint64_t)task); ps("\n");
    uint64_t flags = save_flags_cli();
    
    if (!runq) {
        runq = task;
        task->next = task;  // 循環
    } else {
        task->next = runq->next;
        runq->next = task;
        runq = task;
    }
    
    restore_flags(flags);
    
//    ps("Runqueue head: "); ph((uint64_t)runq); ps("\n");
}

// 補助関数
void task_wait(void) {
    asm volatile("hlt");
}

// --- 変更: weight=0 は budget=0（idle等は即譲る） ---
void set_task_weight(task_t *t, int w){
    if (!t) return;
    if (w < 0) w = 0;
    t->weight = w;
    t->budget = (w == 0) ? 0 : (uint32_t)(w * SCHED_QUANTUM_TICKS);
    t->cond   = (w == 0) ? TASK_READY : TASK_RUNNING;
}

// スケジューラ初期化
int init_scheduler(void) {
    // ps("=== SCHEDULER INITIALIZATION START ===\n");

    // 各タスク作成時に詳細ログ
    idle = create_task(idle_task_entry, 2, "idle_task");
    if (!idle) {
        ps("ERROR: Failed to create idle task\n");
        return -1;
    }
    // ps("✓ Idle task created\n");
    
    task_t* taskA = create_task(task_A_entry, 2, "task_A");
    if (!taskA) {
        ps("ERROR: Failed to create task A\n");
        return -1;
    }
    // ps("✓ Task A created\n");
    taskA->kind = TASK_NORMAL;
    taskA->rip = task_A;
    taskA->cond = TASK_RUNNING;
    
    task_t* taskB = create_task(task_B_entry, 2, "task_B");  
    if (!taskB) {
        ps("ERROR: Failed to create task B\n");
        return -1;
    }
    // ps("✓ Task B created\n");
    taskB->kind = TASK_NORMAL;
    taskB->rip = task_B;
    taskB->cond = TASK_RUNNING;

    task_t* taskC = create_task(task_C_entry, 2, "task_C");  
    if (!taskC) {
        ps("ERROR: Failed to create task C\n");
        return -1;
    }
    // ps("✓ Task C created\n");
    taskC->kind = TASK_NORMAL;
    taskC->rip = task_C;
    taskC->cond = TASK_RUNNING;

    // idle, taskA, taskB を作った直後に
    set_task_weight(idle,  0);                // idle は直ちに手放す挙動に
    set_task_weight(taskA, TASK_SHELL_WEIGHT);    // 比率 3
    set_task_weight(taskB, TASK_NORMAL_WEIGHT);    // 比率 1    
    set_task_weight(taskC, TASK_NORMAL_WEIGHT);    // 比率 1    
    
    
    // ランキューに順番に追加
    ps("\nAdding tasks to runqueue...\n");
    add_to_runqueue(taskA);
    add_to_runqueue(taskB);  
    add_to_runqueue(taskC);

    
    // ps("\nFinal runqueue state:\n");
   
    // ps("=== SCHEDULER INITIALIZATION COMPLETE ===\n");
    return 0;
}

// CLI/STI ヘルパー
uint64_t save_flags_cli(void) {
    uint64_t flags;
    asm volatile("pushfq; pop %0; cli" : "=r"(flags) :: "memory");
    return flags;
}

void restore_flags(uint64_t flags) {
    if (flags & (1ULL << 9)) {  // IF bit
        asm volatile("sti" ::: "memory");
    }
}

static task_t* pick_next(void) {
    uint64_t flags = save_flags_cli();
    task_t* next;

    if (!runq) {                 // 空なら idle
        next = idle;
        goto out;
    }

    task_t* head = runq->next;   // 先頭

    if (!current || current == idle) {
        next = head;             // 初回/idle後は先頭から
        goto out;
    }

    // 循環なので current->next は必ず有効（単一要素なら self）
    next = current->next;

out:
    restore_flags(flags);
    return next;

//    ps("Selected: "); ph((uint64_t)next); ps("\n");
}


// 対応するデバッグ関数も更新
void dump_stack_frame(uint64_t* sp, const char* label) {
    ps(label); ps(":\n");
    for (int i = 0; i < 20; i++) {  // 20要素に拡張
        ps("  ["); ph2(i); ps("]: "); ph(sp[i]); 
        if (i == 15) ps(" (RIP)");
        else if (i == 16) ps(" (CS)");
        else if (i == 17) ps(" (RFLAGS)");
        else if (i == 18) ps(" (RSP)");
        else if (i == 19) ps(" (SS)");
        ps("\n");
    }
}


// --- 追加: 次の“親”だけをRRで選ぶ（weight==0は飛ばす）---
static task_t* pick_next_parent_rr(void){
    if (!runq) return idle;
    task_t* p = (!current || current==idle) ? runq->next : current->next;
    task_t* start = p;
    do{
        if (p->weight > 0) return p;
        p = p->next;
    }while(p != start);
    return idle; // 全部0なら idle
}

// 初期化／切り替え時にこれを書き換える
static inline void set_current_task_id(uint16_t id) {
    current_task_id = id;
}

// 呼び出し側が使う関数
static inline uint16_t get_current_task_id(void) {
    return current_task_id;
}


// スケジューラーの検証部分も更新
void* sched_tick_isr(void* saved_rsp) {
    if (!saved_rsp) return NULL;

    static int call_count = 0;
    call_count++;

    if (exec_current) exec_current->rsp = saved_rsp;
    
    // 基本的な妥当性チェック
    if (!saved_rsp) {
        ps("ERROR: saved_rsp is NULL!\n");
        return NULL;
    }
    
    uint64_t rsp_val = (uint64_t)saved_rsp;
    if (rsp_val < 0x1000000 || rsp_val > 0x80000000 || !is_mapped(saved_rsp)) {
        ps("ERROR: Invalid saved_rsp: "); ph(rsp_val); ps("\n");
        return saved_rsp;
    }

    // いま実際に走っているタスク（SUBなら親に課金）
    task_t* running = exec_current ? exec_current : idle;
    task_t* owner   = owner_of(running);

        // 予算を1tick消費（ownerがNULLはありえないが保険）
    if (owner && owner->weight > 0 && owner->budget > 0) {
        owner->budget--;
    }

    // まだ予算が残っていれば継続実行
    if (owner && owner->budget > 0) return saved_rsp;

        // 予算切れ → 次の親へ。自分の予算を重みに応じて再装填
    // 3) 予算切れ → 重みで再装填
    if (owner) {
        owner->budget = (owner->weight == 0) ? 0
                       : (uint32_t)(owner->weight * SCHED_QUANTUM_TICKS);
    }

    // 現在のタスクのコンテキストを保存
    // if (current) {
    //     // ps("Saving context for current task: "); ph((uint64_t)current); ps("\n");
    //     current->rsp = saved_rsp;
    // } else {
    //     ps("No current task to save\n");
    // }
    if (exec_current) {
        exec_current->rsp = saved_rsp;
    }
    
    task_t* next_parent = pick_next_parent_rr();
    if (!next_parent) return saved_rsp;

    task_t* to_run = next_parent;

    // 4) グローバルの current は「親」のまま更新しておく（←ここが肝）
    current = next_parent;

    // 次のタスクのRSPを詳細チェック
    uint64_t next_rsp_val = (uint64_t)to_run->rsp;
    if (next_rsp_val < 0x1000000 || next_rsp_val > 0x80000000) {
        ps("ERROR: Next RSP out of range: "); ph(next_rsp_val); ps("\n");
        return saved_rsp;
    }
    
    // **修正: 完全なスタックフレームをチェック (SS, RSP, RFLAGS, CS, RIP)**
    if (!is_mapped(to_run->rsp) || !is_mapped((uint64_t*)to_run->rsp + 19)) {
        ps("ERROR: Next RSP not fully mapped\n");
        return saved_rsp;
    }
    
    // スタックフレームの内容を検証
    uint64_t* stack = (uint64_t*)to_run->rsp;
    uint64_t rip = stack[15];
    uint64_t cs = stack[16]; 
    uint64_t rflags = stack[17];
    uint64_t rsp = stack[18];
    uint64_t ss = stack[19];
    
    // RIPの妥当性チェック
    if (rip < 0x100000 || rip > 0x200000 || !is_mapped((void*)rip)) {
        ps("ERROR: Invalid RIP: "); ph(rip); ps("\n");
        dump_stack_frame(stack, "Invalid stack frame");
        return saved_rsp;
    }
    
    if (cs != 0x08) {
        ps("ERROR: Invalid CS: "); ph(cs); ps("\n");
        return saved_rsp;
    }
    
    if (ss != 0x10) {
        ps("ERROR: Invalid SS: "); ph(ss); ps("\n");
        return saved_rsp;
    }
    
    // フラグの最低限チェック
    if ((rflags & 0x202) != 0x202) {
        ps("WARNING: Suspicious RFLAGS: "); ph(rflags); ps("\n");
    }
    
    // RSPの妥当性チェック  
    if (rsp < 0x1000000 || rsp > 0x80000000) {
        ps("ERROR: Invalid task RSP: "); ph(rsp); ps("\n");
        return saved_rsp;
    }
    
    // 5) 実行対象が変わるならスイッチ（比較は exec_current と行う）
    if (to_run != exec_current) {
        set_current_task_id(to_run->tid);
        exec_current = to_run;
        return exec_current->rsp;
    }

//    ps("Task switch approved\n");

    return saved_rsp;

}

// スケジューラ開始
void start_scheduler(void) {
    ps("=== STARTING SCHEDULER ===\n");

    if (init_scheduler() != 0) {
        ps("Scheduler init failed\n");
        return;
    }
    
    // ランキューの状態を詳しく確認
    ps("RUNQ_CHECK:\n");
    if (runq) {
        ps("RUNQ_EXISTS: "); ph((uint64_t)runq); ps("\n");
        
        // ランキューを一周して全タスクをチェック
        task_t* p = runq->next;  // head
        int count = 0;
        ps("RUNQ_TASKS:\n");
        do {
            ps("  TASK["); ph(count); ps("]: "); ph((uint64_t)p);
            ps(" NAME: "); ps(p->name ? p->name : "NULL");
            ps(" KIND: "); ph(p->kind);
            ps(" WEIGHT: "); ph(p->weight);
            ps(" BUDGET: "); ph(p->budget);
            ps("\n");
            p = p->next;
            count++;
            if (count > 10) {
                ps("  RUNQ_LOOP_BREAK\n");
                break;
            }
        } while (p != runq->next);
    } else {
        ps("NO_RUNQ!\n");
    }
    
    // 初期状態設定
    current = idle;
    exec_current = idle;  // これも設定
    
    ps("INITIAL_STATE:\n");
    ps("  current: "); ph((uint64_t)current); ps("\n");
    ps("  exec_current: "); ph((uint64_t)exec_current); ps("\n");
    ps("  idle: "); ph((uint64_t)idle); ps("\n");
    
    ps("=== SCHEDULER STARTED ===\n");
}
