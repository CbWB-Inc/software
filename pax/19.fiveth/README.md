# 19.fiveth.10

# TinyShell（仮）

これは「シェルっぽい何か」です。アセンブラで文字列処理をやる無謀な挑戦から生まれました。

This is a "shell-like something" — born from the reckless attempt to do string parsing in assembly language.

---

## 概要 / Overview

いくつかのコマンドを受け取れるようにしました。  
シェルというにはおこがましいのですが、反応を確認する土台ができました。  

I've made it possible to accept a few commands.  
It's presumptuous to call this a shell, but at least there's a foundation for checking responses now.

---

## 実装の苦しみ / Implementation Struggles

それにしてもアセンブラで字句解析とかやるもんじゃないですね。  
面倒くさいこと面倒くさいこと。  
雑な実装ですがしばらく直す気にはならないと思います。  

Still, lexical analysis in assembly? Definitely not something anyone should be doing.  
Just a heap of tedious work.  
It's a rough implementation, and honestly, I don’t think I’ll be fixing it anytime soon.

---

## 対応コマンド / Supported Commands

- `help` – ヘルプ表示 / Show help  
- `cls` – 画面クリア / Clear screen  
- `locate x y` – カーソル移動 / Move cursor  
- `mem seg:ofs len` – メモリ表示（予定） / Show memory (planned)

---

## 今後の予定 / Future Plans

- セグメント指定付き `mem` 表記（例：`F000:1234`）を受け取れるように  
  Enable `mem` commands with `segment:offset` notation like `F000:1234`

- `atoi` や `atoh` のエラーチェック強化  
  Strengthen error handling in `atoi` and `atoh`

- パーサ部分のマクロ化 or 構造化  
  Refactor the parser into macros or structured routines

---

## 雑感 / Final Thoughts

思い付きで始めたわりには動いてるので満足です。  
ちょっと休憩してから、また気が向いたら整えます。  

Started on a whim, but it works — so I’m content for now.  
I’ll rest a bit and clean things up when I feel like it.

