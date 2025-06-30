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

<Remarks timestamp="2025年6月15日 1:05:23"/>
16.fourth.1
elf形式のコンパイルとリンク、routineは持ち持ち、最低限のirq0割り込み
mainとk_taskの2本立て構成のバージョン
disp_word_hex（正確にはbin_byte_hex）が動かないので代替のdisp_hexは個々に定義する形。
今後のベースにする。

