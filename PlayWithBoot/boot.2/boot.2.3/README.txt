boot.2.3

  or al, al
  一見何をしているかわからない命令です。
  自分自身のorをとったら自分自身になるだけなので
  何をしたいのか意味が分かりません。
  まぁ、これはx86リアルモードの定番表現で
  alが0の時だけZF（ゼロフラグ）が立つという。
  要するにalが０ならば、という分岐判断処理なわけです。
  でも、なんでわかりにくく書くんですかね。
  cmp al, 0x00
  のほうが数百倍わかりやすいのに。
  
  c.f. メモリの1Byteは血の1Byte、クロックの1サイクルは血の1サイクル
       そんな時代があったことは知っています。
       でも…今日日そんなこと気にします？
       メモリがGByte実装されて、クロックがGHzですよ？
       もちろんx86リアルモードらしくてかっこいいのは認めるんですが
       わかりやすく書いても構わないと思うなぁ。
       というわけで、動作が同じ事を実験してみました。


boot2.3

  or al, al  
  At first glance, it’s hard to tell what this instruction is doing.  
  OR-ing a value with itself? That just returns the same value. So… why?

  Well, this is a classic idiom in x86 real mode.  
  It sets the Zero Flag (ZF) only when `al` is zero.  
  Basically, it’s a way to check if `al == 0`.

  But honestly… why write it this obscurely?  
  Wouldn’t `cmp al, 0x00` be a hundred times more readable?

  I get that there was a time when:
    “1 byte of memory is like blood, and 1 CPU cycle is sacred.”  
  But… do we still need to worry about that now?

  With gigabytes of RAM and gigahertz of clock speed?  
  Sure, the x86-style feels “authentic” and I respect that.  
  But I think clarity should be just as valid.

  So I ran a test to confirm that both versions behave the same.


