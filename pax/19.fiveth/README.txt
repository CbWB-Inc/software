19.fiveth

  タスクの役割を整えました。
  子タスクとしてp\task、d_task、孫タスクとしてk_task1～k\task3の5タスク構成になりました。
  キーボードハンドラで行っていたキーコードのデコードをやめ、キーコードを送るだけに専念させました。
  p_taskはキーコードを受け取りデコードを行いキーバッファに格納するようになりました。
  k_task1はキーバッファからアスキーにデコードされたデータを取り出し表示するようになりました。
  各タスクの稼働状態について、最低限の監視機構を実装しました。
  タイマ割り込みの周期を調整しました。
  なんとなくOSっぽくなってきました。


  The roles of the tasks have been organized.
  The system now consists of five tasks: child tasks p_task and d_task, and grandchild tasks k_task1 to k_task3.
  The keyboard handler no longer decodes keycodes and now only sends them.
  p_task receives keycodes, decodes them, and stores them in a key buffer.
  k_task1 retrieves ASCII-decoded data from the key buffer and displays it.
  A minimal monitoring mechanism for task activity has been implemented.
  The timer interrupt period has been adjusted.
  It's starting to feel like an operating system.

