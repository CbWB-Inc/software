boot.5.1

  複数桁の数値の表示ができるようになりました。
  今まではレジスタで計算して表示していましたが
  どこかメモリに設定した値を表示するにはどうしたらいいでしょうか？
  というのが今回のネタ。
  _testというラベルで15を定義してそれを表示します。
  繰り返し処理大活躍です。
  新しくラベルをレジスタに設定して、その中身を表示するという手法も確認できます。
  

boot.5.1

  Now that I can display multi-digit numbers,
  the question becomes: how can I display a value that’s stored in memory?

  Until now, everything was calculated in registers and printed out directly.  
  But this time, I defined the value 15 under a label called `_test`,  
  and I’ll try printing that instead.

  Looping logic comes in handy again here.

  I also tested how to load a memory label into a register  
  and read its contents for display.

  A new experiment in “seeing what's already there.”
