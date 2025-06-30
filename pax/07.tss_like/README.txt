07.tss_like

  マルチタスクの試作です。
  TSSを目指してはいたのですが残念ながらタイムシェアはできていません。
  割り込みがあるたびにタスクの最初から実行されます。
  今までの処理の裏側で別のタスクが動き続けるようにデザインしたのですが
  残念ながら動いてくれませんでした。
  ともあれ、構造的には今後のマルチタスク系のたたき台となるものになっています。


  An experimental attempt at multitasking.
  Although I aimed for a TSS-style design, time-sharing did not work.
  Each interrupt restarts the task from the beginning.
  It was designed so that other tasks could run in the background.
  Unfortunately, this didn’t work as expected.
  Structurally, it forms a basis for future multitasking systems.

