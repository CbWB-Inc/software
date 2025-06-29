boot.1(DiskWrite)

  ディスクの読み込みを試したので、ディスクの書き込みも試しておきます。
  最初にふぁあいるを用意します。
  第1セクタ、第2セクタ、第3セクタの頭にそれぞれ文字列を設定しておいて
  ディスクリードで読み込んだ後、書き換えた内容でディスクライトします。
  バイナリファイルをダンプして、書き換わっていたら成功です。
  もともと設定していた文字列はそれぞれ
  「Forth Gate Open!」
  「Quickly!」
  「Forth Gate Ooen!」
  書き換える文字列は順に
  「All out!」
  「Pull the throttie!」
  「All right Let's Go!」
  結果は大成功でした♪
  
  さて、ちなみに、なんですが。
  文字列の元ネタわかりますか？


boot.1 (DiskWrite)

  After trying out disk reading, it's time to try disk writing too.

  First, I prepared a file with specific strings set at the beginning of  
  the 1st, 2nd, and 3rd sectors:

    - "Forth Gate Open!"
    - "Quickly!"
    - "Forth Gate Oen!"

  The program uses disk read to load them, modifies them in memory,  
  and then writes the changed content back using disk write.

  If a binary dump shows the strings were rewritten — success!

  The new strings written in are:

    - "All out!"
    - "Pull the throttle!"
    - "All right Let's Go!"

  The result? A perfect success! 🎉

---

  By the way...  
  Do you recognize where these original phrases come from?
