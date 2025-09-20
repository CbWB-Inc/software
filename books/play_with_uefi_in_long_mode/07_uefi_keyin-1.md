---
title: "キー入力で遊ぼっ！（１）" # 記事のタイトル
emoji: "🐈"                         # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech"                        # tech: 技術記事 / idea: アイデア記事
topics: ["UTFI","ブート","amd64"]   # タグ。["markdown", "rust", "aws"]のように指定する
published: false                    # 公開設定（falseにすると下書き）
---

## キー入力
文字出力はできるようになりました。
となれば入力もできるようにしたいですね。
なので懐かしのIRQ1を使ってキーボード割り込みを実装しました。


#### 概略
IRQ1によるキーボード割り込みです。
スキャンコードを拾うだけですが
確かにキーボードのUp＆Downを拾っています。


#### 所感
リアルモードから連綿と続いてきたIRQ1です。
感慨深いです。


#### 公開場所
https://github.com/CbWB-Inc/software/tree/main/laboratory/lab01/07_UEFI_keyin-1
