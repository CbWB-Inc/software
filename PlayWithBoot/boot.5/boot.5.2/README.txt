boot.5.2

  新鹿締め定義された数値を表示することに成功しました。
  あらかじめ定義した文字列を表示するは既にやっています。
  ここまで結構地味な実験をしてきましたが
  そろそろ大技を試したいところです。
  『ブートセクタの外に定義したラベルとその中のデータを参照することは可能でしょうか？』
  単純に言ってしまえば、ブートセクタと違う関田を読み込めばいいんですが
  ラベルは参照できるんでしょうか？
  できないと、アドレスで指定せざるを得なくて
  使い勝手が非常に、すこぶる、悪くなります。
  
  ここでちょっと話が合わるんですが、ブートのブログとか資料を見てると
  ブートセクタで津にに読み込むファイルを見つけて
  それを読み込んで実行に移すみたいに書かれています。
  これが大問題で、ファイルがどこにあるかなんてわからないし
  ファイルを配置したバイナリイメージなんて作れないんです。
  ノウハウ無し、知識なし、技術無し。
  この状況でファイルを読むなんて夢のまた夢なんです。
  
  見方を変えると、わたしはファイルシステムの構造とか仕組みを知りたいわけじゃない。
  単に別セクタの値がラベルで参照できるかどうか確認したい。それだけなんですね。
  1024Byteのファイルを作ってもブートでは先頭の512byteしか読んでくれません。
  ならばのこりの512ｂｙては自力で読むしかないわけです。
  ファイルの残りの512Ｂｙｔｅをブートで読み込んだすぐ先においてあげれば
  最初っから1024Ｂｙｔｅ読むのと同じになるんじゃない？
  ラベルも参照できるんじゃない？
  
  という考えのもと、ディスクリードに挑戦するわけです。
  結果は？
  r-aikaちゃん大勝利♪
  Hello 2nd sector!


boot.5.2

  I successfully displayed a statically-defined number.
  String output using predefined data was already working before.

  So far, these have been modest experiments —  
  but now, it’s time for something big.

  “Can I reference a label and its data that lies *outside* the boot sector?”

  In theory, it’s simple: just read another sector into memory.  
  But will labels still work?

  If not, I’d have to use absolute addresses — and that would be… horrifically awkward.

---

  This brings me to an issue:

  Boot blogs and tutorials often say something like:  
  “The boot sector finds a file and loads it for execution.”

  That’s a huge problem.  
  I have no idea where the file is.  
  I can’t build a filesystem-aware image.  
  I have no tools, no knowledge, no prior experience.

  Reading files? That’s still a fantasy.

---

  But let’s shift perspective:

  I’m not trying to understand filesystems.  
  I just want to know:

  **Can I reference a label whose data resides in a different sector?**

  A 1024-byte file gets only its first 512 bytes read by BIOS.  
  So I’ll have to manually read the remaining 512 bytes.

  What if I place the “second half” of the file **right after** the boot sector in the image,  
  and manually read it in using `INT 13h`?

  Wouldn’t that make it feel like I read the full 1024 bytes from the start?  
  Wouldn’t labels work too?

---

  So I tried reading in that second sector.

  The result?

  🎉 r-aika wins big!  
  **Hello 2nd sector!**
