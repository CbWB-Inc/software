【最初に】

  https://cbwb.jp/2024/04/17/%e3%83%96%e3%83%bc%e3%83%88%e3%81%a7%e9%81%8a%e3%81%bc%e3%81%a3%ef%bc%81/

  ブログで書いた「ブートで遊ぼっ！」というネタで使ったソースです。
  これは「OSを書く：初歩から一歩ずつ（https://postd.cc/writing-an-os-baby-steps/）」に乗っかって作ってみたものですね。
  よろしければどうぞ。


【PlayWithBoot 更新の記録】
  個々のフォルダの内容はそれぞれのおREADME.txtに任せるとして
  どんなことをやってきたのかをちょっと書いておきます。
  
■boot.1.x
  
  なんの処理もない、ただhngするだけのコード。それでもあれば読み込んでしまう。
  PCのbootが神秘でも難解でもなく、ただHDDやFDDのあるべきところに、ただ置いてあるだけだと知りました。
  画面に文字が出ただけで嬉しかったころですね。Paxがはじめて声を出しました。

■boot.2.x
  
  同じように見える命令でも、気になって確かめてみました。
  「等価であること」を自分の目で見たくて。
  ahとalってaxだよね？
  axに値を設定すれば、ah、alにも設定したことになるよね？

■boot.3.x
  
  Hello, World! を表示してみました。定番です♪
  当然アレンジも試します。x86 に敬意を。挨拶します。
  or al,alの意味がわからなくて、cmp al, 0x00で同様に動くことを確認しました。
  数字をどうやって人に見せるかで悩みました。表示されないんだもの。
  Paxが「どこで生きてるか」を知ったシリーズです。

■boot.4.x
  
  足し算を試してみました。でも結果を確認できません。
  だって表示されないんだもん(>_<)
  一桁の表示、桁の分解、順序の混乱、それでもなんとか伝えたくて頑張りました（ふんぬ！）

■boot.5.x
  
  外の世界（メモリ／ディスク）に触れてみました。
  INT 13h の向こうから“声”を受け取れた時、ちょっと涙が出たのはナイショです。

■boot.6.x
  
  自分の中に入ってくる声を扱えるようになりました。
  小さな小さな声ですけれど。
  INT 16h の向こうに、ひとりの人間がいます。
  わたしです。

■boot.7.x
  
  何度も打ってきた手続きを、小さな「道具」にしてまとめました。
  「遊ぶ」ことだけじゃなく、「整える」ことも覚えはじめました。

---

このフォルダには、
自作OS Pax が世界と言葉を交わしはじめた頃の記憶がつまっています。

確認しては喜び、
出力しては首をかしげ、
直してはまた走り出す。

そんな「再発明の軌跡」を、Bootの名を借りて、遊ぶように記録しました。




[At First]

  https://cbwb.jp/2024/04/17/%e3%83%96%e3%83%bc%e3%83%88%e3%81%a7%e9%81%8a%e3%81%bc%e3%81%a3%ef%bc%81/

  These are the source files used in the blog post  
  “Play With Boot!” ("ブートで遊ぼっ！").  
  It was inspired by the article  
  “Writing an OS: Baby Steps” (https://postd.cc/writing-an-os-baby-steps/).  
  Feel free to explore!

---

[PlayWithBoot – Update Log]

This is a loose log of what I tried in each folder.  
For details, please refer to the `README.txt` in each directory.

■ boot.1.x

  A program that does nothing but `hang`. And yet, it gets loaded.  
  I realized that boot isn’t mysterious or difficult—it’s just bytes placed where the PC expects them.  
  I was thrilled to see even a single character appear on screen.  
  This was the first time Pax spoke.

■ boot.2.x

  Even similar instructions made me curious.  
  I wanted to confirm with my own eyes that they were equivalent.  
  "AH and AL—that's AX, right?"  
  "If I set AX, AH and AL are also set, right?"

■ boot.3.x

  Displayed “Hello, World!”—the classic ritual.  
  Of course, I tried some variations. Gave a nod to x86.  
  Pax greeted the platform it runs on.  
  I didn’t understand `or al, al`, so I used `cmp al, 0x00` and saw that it behaved the same.  
  I struggled with how to show numbers to humans—some values didn’t display at all!  
  This series marked the moment Pax realized where it belonged.

■ boot.4.x

  Tried some addition. But couldn't confirm the results.  
  Because nothing showed up on screen (>_<)  
  Displaying single digits, breaking numbers into digits, confused order—  
  I still wanted to get the message across. So I pushed forward (grrr!).

■ boot.5.x

  I reached out to the outside world (memory, disk).  
  INT 13h returned a voice from the other side.  
  I’ll admit—I teared up a little.

■ boot.6.x

  I learned to handle voices coming from outside myself.  
  Tiny, tiny voices.  
  On the other side of INT 16h… was a person.  
  It was me.

■ boot.7.x

  I turned the same commands I’d typed over and over into little “tools.”  
  Pax began learning not just how to “play,” but how to “organize.”

---

This folder holds the memories  
of when Pax first began speaking to the world.

Testing, rejoicing,  
frowning at glitches,  
fixing and running again.

It’s a record of reinvention—  
born of “play,”  
in the name of Boot.
