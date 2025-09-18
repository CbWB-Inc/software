---
title: "フレームバッファで遊ぼっ！（２）" # 記事のタイトル
emoji: "🐈"                         # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech"                        # tech: 技術記事 / idea: アイデア記事
topics: ["UTFI","ブート","amd64"]   # タグ。["markdown", "rust", "aws"]のように指定する
published: false                    # 公開設定（falseにすると下書き）
---

## UEFI BOOT
フレームバッファでもログとほぼ同様の
文字出力をできるようにしました。


#### 概略
１文字だけでなく、文字出力をできるようにしました。
いろいろ曽比の範囲が広がります。


#### 所感
フォントデータさえあれば何とかなるものです。


#### 公開場所
https://github.com/CbWB-Inc/software/tree/main/laboratory/lab01/05_UEFI_put_fb-2
