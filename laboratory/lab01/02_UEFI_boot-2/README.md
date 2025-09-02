概要：
    x86_64ロングモードの実験コードです。
    UEFI BIOSではprint等色々準備されていて便利に使えるのですが
    ロングモードに制御を移すと何もできなくなります。
    そのため最低限としてログ出力ができるようにしました。
    com1とデバッグコンソールの出力しています。
    qemuで同一デバイスに出力できないので画面はcom1で
    デバッグコンソールはファイルに落とすようにしています。


Here’s the English version of that overview:

Overview:
    This is experimental code for x86_64 long mode.
    While UEFI BIOS provides useful features such as print, once control is transferred to long mode, 
    none of those are available anymore.
    Therefore, as a minimum capability, I implemented basic logging.
    Output is sent to both COM1 and the debug console.
    Since QEMU cannot output to the same device simultaneously, screen output is routed to COM1, 
    while debug console output is written to a file.
