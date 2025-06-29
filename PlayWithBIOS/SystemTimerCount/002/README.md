# SystemTimerCount 002

## 🗾 概要（Japanese）

思い出しました！

このプログラムは、**システムタイマーを使って命令実行時間を比較する**というものです。  
比較対象は以下の2つ：

- `or al, al`  
- `cmp al, 0x00`

「命令サイズが小さく、クロックが短い方が速いはず？」という仮説を元に、  
実際に差が出るのか確認してみました。

※命令の切り替えは手動で行うため、比較結果が画面に出るタイプではありません。

---

### 💡 結果と考察

結論としては──**差はほぼありませんでした。**

いまどきの CPU はパイプラインもキャッシュもあるので、  
命令バイト長やサイクル数だけで速度が変わる時代じゃないんだなと実感。

なので、**効率が同じなら `cmp al, 0x00` の方が可読性が高くてよさそう**です。

でもまあ……

> `or al, al` が「x86リアルモードっぽくてかっこいい」というのは、認めますｗ

──とはいえ、美学だけで選ぶには根拠が弱くなってきたなぁ、というお話でした 😄

---

## 🌐 Overview（English）

This experiment uses the system timer to compare two instructions:

- `or al, al`  
- `cmp al, 0x00`

The assumption was that smaller byte size and lower cycle counts mean faster execution.

But after measurement (with manual instruction swapping),  
it turns out... there’s virtually no difference.

Modern CPUs with pipelining and caching make such micro-optimizations less meaningful.  
So if efficiency is equal, `cmp al, 0x00` wins for clarity.

That said...  
`or al, al` still *feels* retro and real-mode-cool 😄
