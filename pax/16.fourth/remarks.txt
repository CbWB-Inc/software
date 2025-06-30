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

<Remarks timestamp="2025年6月15日 15:58:35"/>
16.fourth.2.x
修正失敗。回復不能になったので廃棄

16.fourth.3
最低限のキー割り込みが動くバージョン
一応念のためベースとして置いておく

<Remarks timestamp="2025年6月15日 19:19:09"/>
16.fourth.4
キーのデコードを少しだけやったバージョン
このあとグダグダになりそうなのでいったん保存
徹底的に割り切るバージョンを作るならここからやるといいかも

<Remarks timestamp="2025年6月19日 3:21:41"/>
16.fourth.6
ログ周りのデバッグ中だけど
スキャンキーのデコードが一段落したバージョンとして暫定リリース

<Remarks timestamp="2025年6月20日 17:04:35"/>
16.fourth.7

read_log/write_logの実装
routine側だとうまく動かないのでローカルに定義している。
なんでだろうねぇ。

一応Lock関連も実装はしてみたけれど、未テスト。
というか動かすと固まる状態。
routine側にあるからなのか、その地あってもダメなのか不明（というかはっきりさせてない）
組み込むと固まる。（K_taskも固まる）
そういう状況

<Remarks timestamp="2025年6月21日 5:55:31"/>
16.fourth.8

get_key_dataの実装

