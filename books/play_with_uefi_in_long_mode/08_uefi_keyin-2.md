---
title: "キー入力で遊ぼっ！（２）" # 記事のタイトル
emoji: "🐈"                         # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech"                        # tech: 技術記事 / idea: アイデア記事
topics: ["UTFI","ブート","amd64"]   # タグ。["markdown", "rust", "aws"]のように指定する
published: false                    # 公開設定（falseにすると下書き）
---

## UEFI BOOT
IRQ1でのキー割り込みでもよかったのですが
せっかくなのでLAPICでキー割り込みを受けるようにしました。


#### 概略
LAPIC1によるキーボード割り込みです。
こちらもスキャンコードを拾うだけだっけか？
確かにキーボードのUp＆Downを拾っています。


#### 所感
なんとなくロングモードっぽい？
でもスキャンコード体系は古い？


#### 公開場所
https://github.com/CbWB-Inc/software/tree/main/laboratory/lab01/08_UEFI_keyin-2
