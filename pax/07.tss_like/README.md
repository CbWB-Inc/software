

# 07.tss_like

## 🗾 概要（Japanese）

マルチタスク処理の試作です。  
TSS（Task State Segment）を模した設計を目指していましたが、  
現時点ではタイムシェア方式のタスク切り替えは実現できていません。

### 📌 実装の様子

- 割り込みによってタスクを切り替える想定  
- しかし、毎回タスクの**先頭から**再実行される挙動  
- 「別の処理が裏で動き続ける」ような状態は未実現

それでも構造的には、**今後のマルチタスク実装に向けたたたき台**となる内容です。  
記憶保存・スタック操作・割り込み再開点の設計など、課題も見えてきました。

---

## 🌐 Overview（English）

This is an experimental attempt at implementing multitasking.  
It was intended to mimic a TSS (Task State Segment)-like mechanism,  
but true time-sharing task switching was not achieved.

### 🧪 Behavior Summary

- Interrupts were used to trigger task switching  
- However, each task always restarts from the beginning  
- Continuous background execution was not realized

Despite this, the structural design serves as a foundation  
for future multitasking implementations.  
It revealed key challenges, such as state preservation,  
stack transitions, and return address handling.
