# 05.read_exec

## 🗾 概要（Japanese）

ディスクの任意の場所（セクタ）から、任意のメモリアドレスにデータを読み込み、  
そのまま実行を移す機能をもったコマンドインタプリタです。  
処理はファンクションテーブル経由で管理されます。

### 📌 実装されているコマンド

- `cls`  : 画面をクリアする  
- `exit` : プログラムを終了する  
- `help` : 使用可能なコマンドを表示する  
- `3000` : ディスクの 19h セクタを 3000 番地にロードして実行を移す  
- `3800` : ディスクの 19h セクタを 3800 番地にロードして実行  
- `3400` : 同上、アドレスが 3400  
- `3002` : ディスクの 1Dh セクタを 3000 番地にロードし実行  
- `3402` : 同上、アドレスが 3400

### 🛠️ 特徴

- データの読み込みと実行ジャンプを分離せず、直接移動  
- コマンド解析と実行はテーブル参照で行われる  
- 手動ロード型の“ブートローダー未満”な実行環境の実験

---

## 🌐 Overview（English）

A program that loads data from arbitrary disk sectors into arbitrary memory locations,  
and then directly jumps to execute the loaded code.  
Command execution is managed through a function dispatch table.

### 🧪 Supported Commands

- `cls`  – Clears the screen  
- `exit` – Exits the program  
- `help` – Displays help message  
- `3000` – Loads sector 0x19 into address 0x3000 and jumps  
- `3800` – Loads sector 0x19 into 0x3800 and jumps  
- `3400` – Loads sector 0x19 into 0x3400 and jumps  
- `3002` – Loads sector 0x1D into 0x3000 and jumps  
- `3402` – Loads sector 0x1D into 0x3400 and jumps

### 🔧 Features

- Reads and jumps in one step—no intermediate staging  
- Command dispatch is managed via lookup table  
- Experimental "pre-bootloader" environment for manual execution
