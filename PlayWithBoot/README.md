# PlayWithBoot

PlayWithBoot は、自作OS Pax の“はじまり”を記録した実験集です。  
BIOSとINT命令を相手に、1バイトずつ世界を探っていたあのころ。  
このフォルダには、そんな初期ブートコードたちの旅の記録が詰まっています。

---

## 📂 内容について

各 `boot.X.X` ディレクトリには、次のような学びと挑戦が含まれています：

- 数字や文字を画面に出す
- 加算・除算・桁分解などの算術処理
- セクタ読み出し（INT 13h）
- キーボード入力（INT 16h）
- 表示ルーチンやサブルーチンの導入
- コードとデータの分離、再利用の第一歩

それぞれの実験は、それぞれの `README.txt` に記録されています。

---

## 🎓 目的とスタンス

このフォルダは「最適化」や「完成」を目指すものではありません。  
むしろ、**“動いたときに自分が何を感じたか”** を大切に記録したログです。

技術の地図ではなく、気持ちの地層。  
構文の正しさよりも、動いたときのよろこびを。

---

## 🛠 実行環境（例）

- `nasm` で `.asm` をバイナリに変換
- `qemu-system-i386` や `bochs` にて起動確認
- USB書き込みして実機で確認…など、お好みで

---

## 🔖 補足

このコードたちは、r-aikaが「Bootで遊ぼっ！」という気持ちを大事にしながら書いた記録です。  
どこかに似た想いを持っている方に、少しでも伝わったら幸いです。




# PlayWithBoot

PlayWithBoot is a collection of early experiments that trace the beginnings of a self-made OS called Pax.  
Back when BIOS calls and INT instructions were my playmates, I explored the world one byte at a time.  
This folder captures the journey of those first boot code attempts.

---

## 📂 Contents

Each `boot.X.X` directory contains a small experiment or discovery, such as:

- Printing numbers and characters on the screen  
- Arithmetic operations: addition, division, digit splitting  
- Reading sectors via `INT 13h`  
- Capturing keyboard input via `INT 16h`  
- Writing output and utility subroutines  
- Separating code and data, and learning to reuse routines

Each folder contains its own `README.txt` with a brief note about that version.

---

## 🎓 Purpose & Philosophy

This isn’t a project aiming for efficiency or completion.  
Instead, it’s a series of logs that value **how it felt** when something first worked.

More a sediment of emotion than a map of technology.  
More about the joy of movement than the correctness of syntax.

---

## 🛠 Environment (example setup)

- Assemble with `nasm` to generate `.bin` files  
- Test using `qemu-system-i386` or `bochs`  
- Or burn to USB and try it on a real machine — if you're feeling brave!

---

## 🔖 Notes

These code fragments were written by [r-aika](https://cbwb.jp/)  
as part of the “Play With Boot!” journey.

If this resonates with your own curiosity,  
I hope you’ll find something warm and familiar inside.

And perhaps —  
the first time Pax said “Hello” to the world...  
was really the moment it whispered “Welcome back” to me.

