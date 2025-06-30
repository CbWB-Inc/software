# 04.cmd_prompt

## 🗾 概要（Japanese）

他で作成した `one_line_editter` を使用して、簡単なコマンド実行に対応させたものです。

### 📌 実装コマンド一覧

- `cls` — 画面をクリアする  
- `exit` — プログラムを終了する  
- `exec` — 入力文字列をそのまま表示する（実行はしない）  
- `help` — 使用可能なコマンドを表示する

`exec` は現時点では入力エコーのみを行うダミーコマンドです。  
軽量なシェル的UIの実験として設計されています。

---

## 🌐 Overview（English）

This program extends the previously created `one_line_editter` to handle basic command execution.

### 🧪 Supported Commands

- `cls` — Clears the screen  
- `exit` — Exits the program  
- `exec` — Displays the entered string (no execution)  
- `help` — Lists available commands

Currently, `exec` is a placeholder that simply echoes the input.  
This serves as a small experiment in building a minimal shell interface.
