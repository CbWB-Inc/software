echo

  キーボードから文字列を取り込んでアドレスをaxに返すルーチンを作ります。
  打ち込んだ文字列を単に表示するだけです。
  本体はget_str_ascii
  実行はexp_echo
  で行っています。
  あと、必要そうなサブルーチンを持っています。


  MEMO
  BIOSコール確認
	0x16	Keyboard Services
		0x10	Enhanced Read Keyboard
		0x11	Enhanced Read Keyboard Status
		0x12	Enhanced Read Keyboard Flags


echo

  This is a simple echo program.

  It defines a routine that reads a string from the keyboard  
  and returns its memory address in AX.

  The input is then printed back to the screen as-is.

  The core routine is `get_str_ascii`,  
  and the execution entry point is `exp_echo`.

  A few support subroutines needed for this functionality are also included.

