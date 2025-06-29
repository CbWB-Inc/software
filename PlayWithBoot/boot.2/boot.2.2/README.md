# boot.2.2

## 🗾 概要（Japanese）

```asm
mov ah, 0x00  
mov al, 0x03
って、これ……

AHとALを合体させたのがAXなんだから、

asm
mov ax, 0x0003
でよくない？

と思って、実際に試してみた回です。


🌐 Overview（English）

mov ah, 0x00  
mov al, 0x03
But then I realized...

Since AX is just AH and AL combined, shouldn't this work too?

asm
mov ax, 0x0003
So I gave it a try.
