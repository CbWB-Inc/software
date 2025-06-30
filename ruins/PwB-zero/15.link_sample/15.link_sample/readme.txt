X86系のレガシーと戯れます。

<Remarks timestamp="2025年6月14日 18:11:55"/>
全シンボルの配置アドレスの表示

nm -n kernel.elf

putcが知りたければ
nm -n kernel.elf | grap putc


elf形式だとtimes n db 0によるパディングは無効になることが多い？
単にエリアを食うだけ。
