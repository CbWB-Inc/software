05.read_exec

  ディスクの任意の場所からメモリの任意の場所に読み込んで
  コマンドテーブル経由で実行を移すプログラム
 入力できるコマンドは以下の通り
  cls   : 画面をクリアする
  exit  : 処理を終了する
  3000  : ディスク19セクタを3000番地に読み込んで実行を移す
  help  : ヘルプメッセージを表示する
  3800  : ディスク19セクタを3800番地に読み込んで実行を移す
  3400  : ディスク19セクタを3400番地に読み込んで実行を移す
  3002  : ディスク1dセクタを3000番地に読み込んで実行を移す
  3402  : ディスク1dセクタを3400番地に読み込んで実行を移す


  Loads from an arbitrary disk location into an arbitrary memory location
  A program that transfers execution via command table
  The available commands are as follows
  e.g., “Load sector 0x1D into 0x3400 and jump”

