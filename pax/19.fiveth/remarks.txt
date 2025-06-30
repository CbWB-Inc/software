X86系のレガシーと戯れます。

<Remarks timestamp="2025年6月22日 16:00:31"/>
shellもどきの続き？

<Remarks timestamp="2025年6月23日 13:13:59"/>
19.fiveth.1

タイマ割り込み  h0
キーボード割り込み  h1
基本タスク  k_task、d_task
派生タスク  p_task1～3

が動くバージョン
以降のベースになるのかしら


<Remarks timestamp="2025年6月23日 19:33:19"/>
19.fiveth.1
get_keyの実装
キーボード入力から文字コードとステータスを取得するところまで
共通化するとバグりそうなので個別に使用する状況


<Remarks timestamp="2025年6月25日 2:06:31"/>
19.fiveth.2
タイマ周期、表示等、微調整したもの。
見た感じでは一応安定している。

get_keyを共通ルーチンにするところまで。



<Remarks timestamp="2025年6月26日 10:44:52"/>
19.fiveth.3
putcd, disp_word_hexd, sidp_strdの実装
scandata_decodeの調整


<Remarks timestamp="2025年6月28日 8:42:35"/>
19.fiveth.5
taskの稼働状態について、最低限の監視機構を実装


0008
0008







<Remarks timestamp="2025年6月14日 18:11:55"/>
全シンボルの配置アドレスの表示

nm -n kernel.elf

putcが知りたければ
nm -n kernel.elf | grap putc


elf形式だとtimes n db 0によるパディングは無効になることが多い？
単にエリアを食うだけ。


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

