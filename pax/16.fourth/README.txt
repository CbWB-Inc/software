16.fourth

  子タスクを1つに絞りました。タスク間通信に特化しています。
  キーボード割り込みに対応しました。専用リングバッファを介して子供にデータを送ります。
  キーコードを受け取ったハンドラはデコードしてキーステータスとアスキーコードを返します。
  リングバッファの先頭の状態と送受信されるデータが表示されるようになっています。
  マルチタスクしていることがよくわかる構成です。


  The number of child tasks was reduced to one.
  It specializes in inter-task communication.
  Keyboard interrupts are now supported.
  A dedicated ring buffer is used to send data to the child task.
  The handler receives key codes, decodes them, and returns key status and ASCII.
  The buffer head and transmitted data are displayed.
  The structure clearly shows that multitasking is taking place.

