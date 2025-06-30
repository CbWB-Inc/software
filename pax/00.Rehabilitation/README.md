# 00.Rehabilitation

## 🗾 概要（Japanese）

約1年ぶりに手を動かすための「リハビリ」用プログラムです。  
環境の整合性チェックと、BIOSまわりのカンを取り戻すために作りました。

やっていることはとてもシンプル：

- 方向キー入力を受け取り、カーソルを動かすだけ  
- BIOS割り込み（INT 0x10）を用いて、カーソル位置を制御  
- 上下左右に素直に動作するだけの構成です

### 📌 動作のイメージ

1. 画面に何かが表示されている状態からスタート  
2. ユーザーが方向キーを押す  
3. カーソルがその方向に動く（画面内容に変化はなし）

純粋なI/Oとの再会を楽しむ、準備運動的な一章です。

---

## 🌐 Overview（English）

A simple “rehabilitation” program to reawaken familiarity with BIOS-level programming  
after roughly a year away from development.  
Its purpose is to check the environment and recover a sense of low-level control.

### 🔧 What It Does

- Accepts arrow key input and moves the cursor accordingly  
- Uses BIOS interrupt `INT 0x10` (function `AH=0x02`) to set the cursor position  
- There are no visual effects — just direct cursor movement

A minimal, muscle-memory reboot.  
No colors, no blinking — just motion.  

And that’s enough, for now. 🕹️
