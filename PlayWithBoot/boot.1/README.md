# boot.1

## 🗾 概要（Japanese）

PCをブートするのって、高尚な呪文を使って玄妙な世界を操作する特別な人だけができる……  
そんなふうに思っていたころがありました。

でもそれを壊してくれたのが、このシンプルなブートプログラム。

必要なのはたったこれだけ：

- 起動メディアの第0セクタに配置されていること
- セクタの終端が `0x55AA` であること

それだけでPCは勝手に読んで、実行してくれます。

なにか特別な命令がなくても、暴走でもいいならもうブートできちゃう。  
それはさすがに寂しいから、無限ループだけ入れてあります。  
でもそれだけです。

**それでも、PCは起動してくれるんです。驚きですね。**

---

## 🌐 Overview（English）

I used to believe that booting a PC required arcane spells—  
that only chosen people could touch the mystical world of bootloaders.

But this tiny boot program shattered that belief.

Turns out, all a PC needs to boot is:

- The code must reside in the 0th sector of the boot device
- It must end with the magic signature `0x55AA`

That’s it.

No complex instructions needed—if you're fine with just booting into chaos.  
To keep things polite, I've added an infinite loop.  
But that’s all.

**And still, the PC boots. Isn’t that amazing?**

---

## 🧪 実行方法（How to Run）

```bash
qemu-system-x86_64 boot.bin
