boot.2.2

  mov ah, 0x00
  mov al, 0x03
  これって…。ahとalを合体させたのがaxなんだから…
  mov ax, 0x0003
  でよくない？
  と思って試してみました。


boot.2.2

  I was originally writing:

    mov ah, 0x00
    mov al, 0x03

  But then I thought…
  "AH and AL are just parts of AX, right?  
   So couldn’t I just write: mov ax, 0x0003?"

  And so, I tried it out.
