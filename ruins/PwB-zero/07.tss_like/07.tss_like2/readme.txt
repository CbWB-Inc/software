X86系のレガシーBIOS:ビデオ系と戯れます。

<Remarks timestamp="2025年5月24日 10:21:00"/>
funcとfunc2はmainから直接実行
func3とfunc4はtss実行
これが最終イメージ

まずはfunc3をtss実行するところ。
最初から両方じゃないと無理か。
そんな気がしてきた。
今でも割り込み実行してるしなぁ。

231F  x
2321  y
2323  i
2325  j
2327  k
2aa2  after_func