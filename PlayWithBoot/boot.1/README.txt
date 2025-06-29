【boot.1】

  PCをブートするのって高尚な呪文を駆使しないといけないと思ってました。
  何か特別な仕組みとか使って玄妙な世界を操れるのは選ばれた能力のある人たちなんだと。
  そんな考えを破壊してくれたのがこのブートプログラム。
  PCのブートに必要なのは2点だけ。
  ブートセクタ（起動メディアの第0セクタ）にあること。
  セクタの終了が0x55AAであること。
  これだけだったんです。
  これだけあればPCが勝手に読んでくれちゃう。
  何かをさせたいのであれば別途命令が必要なのは当然なのですが
  ブートして暴走するでよければ命令さえいらない。
  それも心地よくないので無限ループさせてますが
  それだけです。
  これだけでPCはブートしちゃうんです。
  驚きですね。

  実行の仕方：
    qemu-system-x86_64 boot.bin


[ boot.1 ]

  I used to think booting a PC required lofty incantations.  
  That only the chosen ones—with special skills—could control such arcane worlds using mysterious mechanisms.

  This tiny boot program shattered that belief.

  Turns out, a PC only needs two things to boot:

  - The code must be placed in the boot sector (the 0th sector of the boot medium)
  - It must end with the magic bytes: 0x55AA

  That’s it.

  With just that, the PC willingly reads it on its own.

  Of course, if you want it to actually *do* something, you’ll need additional instructions.  
  But if you’re okay with booting straight into chaos—no instructions are even necessary.

  That felt... unsatisfying.  
  So I added an infinite loop.

  And that’s it.

  Even just that is enough to make the PC boot.

  Amazing, isn’t it?

  How to run:
      qemu-system-x86_64 boot.bin
