boot.4.3

  1～100まで足すと合計で5050になるわけなんですが
  5050にマジックナンバーの30を足したら5080。
  これをint 0x10は表示してはくれませんでした。
  そりゃそうです。30足すのは1文字文ですし
  5050は5,0,5,0の4文字なんですから。
  複数文字の表示にはさらなる工夫が必要になります。
  まずは一番簡単な2桁の数字を表示してみましょう。
  例えば12を表示しようと思います。
  これは1to2の表示に分けられます。
  12という数字を1という数字、2という数字に分ける必要があります。
  どうするか？
  割り算を使います。
  12を10で割った答え（商）が1、余り（剰余）が２となって
  ちょうど欲しい値になるわけです。
  12を10で割った答えと余り
  懐かしいですねｗ
  小学校4年生の算数ですｗ
  これを1文字ずつ表示するのですが
  本来なら１→２と表示したいところ、
  余りは2から先に手に入ってしまうので
  逆順、すなわち2→1とひょうじすることになります。
  ま、商品じゃないし。作っている本人が逆順だって知ってれば
  問題ないでしょう。
  

  
boot.4.3

  Adding numbers from 1 to 100 gives 5050.  
  Now if I add the “magic number” 30, I get 5080.  
  I tried printing that with INT 0x10… and failed. 😭

  Makes sense — 30 is a single-digit ASCII offset,  
  but 5050 is four characters: 5, 0, 5, 0.

  So… to print multi-digit numbers, I’ll need something smarter.

  First, let’s try something easy: displaying a two-digit number — like 12.

  That means breaking it down into 1 and 2.

  How?  
  With division!

  12 ÷ 10 → quotient: 1, remainder: 2  
  That gives me exactly the digits I need.

  Ahh, brings back memories… 4th grade math 😄

  The tricky part: the remainder (2) comes first, so I’ll end up printing **2 → 1**.

  Not ideal, but hey — I wrote it. I know what it means 😌
