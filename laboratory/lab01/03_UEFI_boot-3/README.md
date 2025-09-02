概要：
    x86_64ロングモードの実験コードです。
    最低限ログが出せるとはいえWindowが上がっているのに
    何も表示できないのはさみしいものです。
    とはいえWindowni表示するためにはフレームバッファが必要で
    フレームバッファを使うためにはページングが必要です。
    というわけでフレームバッファを使えるようにするためにページングをしました。


Here’s the English version of that overview:

Overview:
    This is experimental code for x86_64 long mode.
    Even though minimal logging is possible, having a screen open with nothing displayed feels rather empty.
    However, to display anything on the screen, a framebuffer is required, and to use the framebuffer,
    paging must be set up.
    Therefore, paging was implemented to enable the use of the framebuffer.
