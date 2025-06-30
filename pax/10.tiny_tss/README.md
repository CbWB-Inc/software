# 10.tiny_tss

## 🗾 概要（Japanese）

TSS（Task State Segment）の導入に挑戦したマルチタスク実装です。

これまでの擬似マルチタスクでは、タスクの中断後に毎回「最初から」実行される構成でした。  
今回の実装では、**割り込みによって中断されても、再開時には中断箇所から実行が再開されます**。  
これにより、より本格的なマルチタスク動作に近づきました。

### 📌 特徴

- TSS風の構造体を用いてレジスタ情報などを管理  
- 割り込みごとに異なるタスクの状態を保存・復元  
- ユーザー入力などのUI機能は削除し、**マルチタスク処理に特化**

これは見た目の派手さよりも「構造と挙動の確立」に焦点を置いた、**基礎の礎**です。

---

## 🌐 Overview（English）

This is a multitasking implementation that introduces a TSS (Task State Segment)-like structure.

In previous versions, multitasking would restart each task from the beginning upon every interrupt.  
With this version, **execution resumes from the exact point of interruption**, allowing for more realistic and structured multitasking behavior.

### 🧪 Key Features

- Simulates TSS-like structures to manage register states  
- Interrupt-driven saving and restoring of task context  
- Drops user input support to fully focus on background multitasking

Visually minimal, but architecturally pivotal —  
a foundational piece that enables future evolution in task management.
