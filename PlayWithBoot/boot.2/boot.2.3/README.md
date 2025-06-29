# boot.2.3

## 🗾 概要（Japanese）

```asm
or al, al
一見、何をしてるかよくわからない命令です。 自分自身にORをとったって、結果は元の値そのままですよね。 何を意図してるのか…？

実はこれは、x86リアルモードではよく使われる記法で、 al == 0 のときだけ Zero Flag（ZF）が立つという動作になります。 つまりこれは「alが0かどうかを調べる」命令だったんです。

でも……

asm
cmp al, 0x00
って書いたほうが、よっぽどわかりやすくないですか？😅

もちろん、「メモリの1バイトは血の1バイト」みたいな時代があったことは知っています。 でも……今って、RAMはギガバイト、クロックはギガヘルツ。

読みやすさ重視でもいいじゃない？ というわけで、両者の動作が同じかどうか、実験してみました。

🌐 Overview（English）
asm
or al, al
At first glance, this instruction looks meaningless. OR-ing a register with itself just gives the same value. So… what’s the point?

Actually, in x86 real mode, this is a common trick. It only sets the Zero Flag (ZF) when al == 0. So it's used as a test to check whether al is zero.

But still...

asm
cmp al, 0x00
Wouldn’t that be so much more readable? 😅

Sure, I get it—there was a time when “a byte of memory was like blood, and a single cycle sacred.” But nowadays, we’ve got gigabytes of RAM and multi-GHz CPUs.

I think clarity should be okay too.

So I ran a test to compare both versions.

