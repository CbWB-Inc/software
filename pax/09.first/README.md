# 09.first

## 🗾 概要（Japanese）

これまでの実装要素を集約した、デモンストレーション用プログラムです。  
キーボードからのコマンド入力を受け付け、Enterキーで実行を確定します。  
`help` コマンドを使うことで、利用可能なコマンド一覧が表示されます。

指定されたコマンドに応じて、ディスク上の特定セクタをメモリに読み込み、  
そのアドレスに制御を移して処理を開始します。

### 🧵 特筆点

- 2つのタスクが同時実行される構成（擬似マルチタスク）  
- TSS（Task State Segment）は使用していないが、割り込みベースでタスクを切り替え  
- ユーザー入力を通じて外部プログラムをロードし制御を委譲

ここに至るまでの流れを体現した、ひとつの「区切り」的成果物です。

---

## 🌐 Overview（English）

A demonstration program that brings together the core techniques developed so far.  
It accepts keyboard input for commands, and executes the selected action upon pressing Enter.  
The `help` command displays the list of available options.

Depending on the command, a specific disk sector is loaded into memory,  
and control is transferred directly to that memory location.

### 🧪 Key Highlights

- Two tasks are running concurrently (pseudo-multitasking)  
- TSS is not used, but interrupt-based switching provides task interleaving  
- External code is dynamically loaded and executed based on user commands

This marks a milestone — a snapshot of the system’s evolving design and the culmination of experimentation thus far.

