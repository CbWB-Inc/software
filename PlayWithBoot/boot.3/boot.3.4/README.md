# boot.3.4

## 🗾 概要（Japanese）

数字をそのまま表示しようとしても、思ったように出力されない……  
ということで、数字を **“文字として扱ってから出力する”** ように変更しました。

C言語をやってる人ならおなじみですね。  
いわゆる `itoa` 関数と同じような働きを、自前で実装してみた回です。

---

## 🌐 Overview（English）

You can’t just “print a number” as-is using BIOS calls —  
you first need to convert it into **ASCII characters**.

So in this version, I implemented a simple routine  
similar to what C’s `itoa()` function does —  
breaking the number into digits and printing them one by one.
