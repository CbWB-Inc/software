# boot.1 (DiskWrite)

## 🗾 概要（Japanese）

ディスクリードができたら……やっぱり次はディスクライトも試したくなりますよね！💡

というわけで、**書き込み実験に挑戦**です。

まずは第1〜第3セクタに、それぞれ以下の文字列を設定したバイナリファイルを用意：

- 「Forth Gate Open!」  
- 「Quickly!」  
- 「Forth Gate Ooen!」←（Ooen…？タイプミスも含めてネタ感！）

それらをディスクリードで読み込んでから、  
メモリ上で文字列を書き換え、**INT 13h** でディスクライト！

成功したかは、バイナリをダンプして確認です。

書き換えた内容は、以下のとおり：

- 「All out!」  
- 「Pull the throttle!」  
- 「All right Let's Go!」

結果は……

**大・成・功！🎉**

---

## 🌐 Overview (English)

After experimenting with reading from disk, it was time to try **writing**.

To do this, I prepared a binary file with strings at the start of  
the 1st, 2nd, and 3rd sectors:

- "Forth Gate Open!"  
- "Quickly!"  
- "Forth Gate Oen!"

These were loaded via disk read, updated in memory,  
and written back with `INT 13h` disk write.

Verification was done by dumping the file and confirming the rewrite.

The new strings written were:

- "All out!"  
- "Pull the throttle!"  
- "All right Let's Go!"

And the result?

**Perfect success!** 🎉

---

## 🔎 元ネタ、わかりますか？

Now then… by the way…  
**Do you recognize where those original strings came from?**

