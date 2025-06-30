X86系のレガシーと戯れます。

<Remarks timestamp="2025年6月14日 18:11:55"/>
全シンボルの配置アドレスの表示

nm -n kernel.elf

putcが知りたければ
nm -n kernel.elf | grap putc


elf形式だとtimes n db 0によるパディングは無効になることが多い？
単にエリアを食うだけ。


<Remarks timestamp="2025年6月15日 0:39:03"/>
動かないルーチン
  disp_word_hex
    bin_byte_hex

<Remarks timestamp="2025年6月22日 1:47:28"/>
開始


プログラム側
  qemu-system-i386 -fda os.img -s -S
  ↓
  make DEBUG


GDB側
  端末立ち上げ
  gdb kernel.elf
  set architecture i8086
  arget remote localhost:1234
  continue


continue	実行を再開する
Ctrl+C	強制的に一時停止（割り込み）
stepi	1命令ずつ実行
info registers	現在のレジスタ状態を確認
backtrace	呼び出し元を表示（使える場合）

x/10i $eip  10命令表示
break シンボル
info registers
x/16xw $sp        spを１６レベル表示
print             表示
$xx               レジスタ参照
list              現在の関数とかの表示
info line         現在行の情報
list 関数名       関数の表示
step              ステップイン
next              ステップオーバー
continue          実行

<Remarks timestamp="2025年6月22日 13:06:38"/>
いちおうOKにしちゃおうか
これから先はroutineの整理という感じで
