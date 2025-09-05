---
title: "UEFIブートで遊ぼっ！"       # 記事のタイトル
emoji: "🐈"                         # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech"                        # tech: 技術記事 / idea: アイデア記事
topics: ["UEFIブート","amd64"]      # タグ。["markdown", "rust", "aws"]のように指定する
published: false                    # 公開設定（falseにすると下書き）
---

## UEFI BOOT
レガシーBOOTではそれなりに遊んだので、UEFI BOOTでも同様に遊んでみようかと思いました。
まずは第一歩として、UEFI BOOTして、kernelに制御を移すところまでです。
開発環境はWindows11 ＋ wsl（Debian）＋VSCode＋QEMU です。

#### 概略
ブートさせること自体が目的です。UEFI BOOTから空のkernelに制御が移れば成功となります。
BOOT側では以下の処理を行っています。
・BOOT
・各種情報取得
・kernelファイル検索
・kernelファイル読み込み
・kernelへジャンプ

#### 所感
bootdisk/EFI/BOOTというフォルダ内にBOOTX64.EFIという実行ファイルを置けば読み込んで実行されます。レガシーブートのMBRの位置づけですね。
最初、関数コールでkernelに遷移させようと思ったのですがうまくいかず、結局レガシーブート同様にメモリ内にカーネルイメージを読み込んだ後、そのアドレスへジャンプという構成になりました。
ブートだけでかなり試行錯誤してしまいました。
以下で公開しておくので、興味があればご覧ください。

#### 公開場所
https://github.com/CbWB-Inc/software/tree/main/laboratory/lab01/01_UEFI_boot-1
