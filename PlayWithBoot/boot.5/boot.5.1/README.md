# boot.5.1

## 🗾 概要（Japanese）

複数桁の数値を表示できるようになったので、  
**「メモリにある既存の数値」をどう表示するか**に挑戦してみました。

これまでの boot シリーズでは、演算結果（レジスタの中身）を表示していましたが、  
今回は `_test` というラベルで **値 15** を定義し、それを画面に出してみます。

- `mov si, _test` のようにしてラベルアドレスをレジスタに代入  
- その先にあるデータ（1バイト）を読み取り  
- 数値として変換 → 1桁ならそのまま、複数桁なら分解して出力！

**繰り返し処理、大活躍！**  
boot.4.5 で作った「10で割るループ」がそのまま応用できるのが嬉しいところです。

---

## 🌐 Overview（English）

Now that displaying multi-digit numbers works,  
this version explores how to show **a value stored in memory**.

Previously, all numbers were calculated in registers.  
But in this experiment, I defined the value 15 under a label called `_test`,  
and read that memory directly for display.

- Load the address of `_test` into a register (like `SI`)
- Read the byte at that address
- Convert and display the number

The looping logic from earlier — dividing by 10 and printing remainders —  
is used again here, now with data sourced from memory.

A small shift…  
from “what I compute” to “what already exists.”
