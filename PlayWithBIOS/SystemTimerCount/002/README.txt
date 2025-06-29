SystemTimerCount  002

  思い出しました。
  これ、システムタイマー使って処理時間を測定しています。
  比較対象は以下の二つ
    or al, al
    cmp al, 0x00
  
  実行クロック数が短く、命令バイトが小さいほど早い
  これが本当か、本当だとしてどれくらい差があるのか
  確認しようというプログラムです。
  命令の書き換えは書道で行うので、実行したら比較結果が表れるわけではないのですが
  それなりに面白い結果になりました。
  結果として、差がなかったということです。
  ていうか、現状パイプラインやキャッシュがガンガン聞いている状況で
  クロック数も命令バイト長も速度に影響あると思えないんですよね。
  効率が変わらないのであればわかりやすく
    cmp al, 0x00
  を使ったほうが良いということになります。
  まぁ、前にも書きましたけど、
  『or al, alってx86リアルモードっぽくてかっこいい』
  というのは認めますｗ
  でも強制力と説得力は根拠なくなるかなぁと。


SystemTimerCount 002

  I remembered what this was for!

  This program uses the system timer to measure execution time.  
  Specifically, it's comparing:

    or al, al  
    cmp al, 0x00

  The hypothesis is: fewer CPU cycles and smaller instruction size → faster execution.  
  So I wanted to see if that actually holds true, and if so, by how much.

  Instruction swapping is done manually,  
  so the program doesn’t automatically show the results — you check them yourself.

  In the end, the difference was... negligible.

  With pipelining and caching in play,  
  neither the clock count nor the byte size seems to matter all that much anymore.

  So if efficiency is the same,  
  I’d say `cmp al, 0x00` is clearer and more readable.

  Though... yeah, I admit —  
  "or al, al" *does* feel more x86-real-mode and stylish 😄

  Still, I think the aesthetic alone isn't enough to justify it anymore.
