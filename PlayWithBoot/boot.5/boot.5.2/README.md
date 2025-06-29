# boot.5.2

## 🗾 概要（Japanese）

静的に定義された数値の表示に成功しました。  
事前に定義した文字列の表示もすでにできています。

でも、ここまでの実験はちょっと地味……  
そろそろ「大技」に挑戦したいところです。

---

### 💡 テーマ

**「ブートセクタの外にあるラベルやその中のデータを参照できるか？」**

仕組みとしては単純です：

- 別のセクタを `INT 13h` で読み込む  
- その先に定義されたラベルを使ってアクセスする

でも……本当に**ラベルが機能するのか？**

もしダメだったらアドレス直指定しなきゃいけなくて、それはさすがに面倒です。

---

### 📉 小さな問題、大きな壁

よくある「ブートセクタがファイルを見つけて読み込む」って資料──  
**あれ、正直無理ゲーです。**

- ファイルがどこにあるか分からない  
- バイナリイメージをファイル単位で構築できない  
- ノウハウも知識も技術もない

今のわたしにファイルを読むなんて、**夢のまた夢**。

---

### 🔍 本当にしたいことは何か？

ファイルシステムの学習じゃない。  
**「別セクタにある値をラベルで参照できるか」──それだけ。**

BIOSが読んでくれるのは先頭512バイトだけ。  
ならば、**残りの512バイトを自分で読み込んで、そのすぐ後に置いておけばいい。**

つまり、1024バイトの構成でも、**ラベルが生きたままにできるかもしれない！**

---

## ✅ 結果

試してみました。`INT 13h` でセクタを追加ロード。

結果は――

🎉 **r-aikaちゃん、大勝利！**  
**Hello 2nd sector!**



## 🌐 Overview (English)

I successfully displayed a statically defined numeric value — and I’d already been printing strings defined in memory.

But now it’s time for something bigger.

---

### 💡 Theme

**Can I reference a label (and its data) that exists *outside* the boot sector?**

In theory, it should work:
- Load an additional sector using `INT 13h`
- Access the label placed in that sector

But the real question is: **will the assembler-generated label still work after loading additional data manually?**

If not, I’d have to use raw memory addresses — which is far less convenient.

---

### 📉 The real-world problem

Many boot tutorials say something like:  
“The boot sector loads a file and passes control to it.”

But that’s a big problem.

- I don’t know where the file is
- I can’t build a binary image that places files correctly
- I have no tools, no knowledge, no experience

In this environment, “reading a file” is a distant dream.

---

### 🔍 What I really want to know

I’m not aiming to learn the structure of a filesystem.

I just want to check:

> Can I reference a label and its data from another sector?

BIOS only loads the first 512 bytes of a file.  
So what if I place another 512 bytes *right after* the boot sector in the image,  
and use `INT 13h` to read it in manually?

Wouldn’t that effectively create a 1024-byte memory region, with all labels intact?

---

### ✅ Result

I tried it. I read the second sector.

And it worked.

**r-aika wins again!** 🎉  
_“Hello 2nd sector!”_
