# echo

## 🗾 概要（Japanese）

キーボードから入力された**文字列をそのまま表示する**簡単な echo プログラムです。

主な構成は以下のとおり：

- `get_str_ascii`: 文字列をキーボードから取得して、アドレスを `AX` に返すルーチン  
- `exp_echo`: 実行エントリーポイント。入力取得 → 表示を行う  
- 必要なサブルーチン群も付属しています

### 📌 動作のイメージ

1. ユーザーが何か文字列を打つ  
2. メモリに格納し、そのアドレスを `AX` に格納  
3. リターンかCTRL+リターンが入力されたら終わる
4. アドレスが指す内容を画面に表示（echo）

---

## 🌐 Overview（English）

This is a basic echo program.

The core routine, `get_str_ascii`, waits for keyboard input,  
stores the resulting string in memory, and returns its address via the `AX` register.

The execution starts from `exp_echo`,  
which ties together input and output to reflect the typed string.

Several useful subroutines are also included for handling common string and memory tasks.

A simple, foundational step —  
but one that marks Pax’s first two-way interaction 🌱

