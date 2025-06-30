# 04.func_table

## 🗾 概要（Japanese）

先の簡易コマンド実行ルーチンを、ファンクションテーブル形式に再構成したものです。  
コマンド名と対応する処理関数をテーブルで管理することで、処理分岐の明快さと拡張性が向上しました。

### 📌 特徴

- コマンド名（文字列）とハンドラ関数のマッピングを定義  
- 入力に応じて対応関数を呼び出すルックアップ方式  
- コマンドの追加・削除が容易

「壊れにくく、育てやすい」構造への第一歩といえる実装です。

---

## 🌐 Overview（English）

This is a refactored version of the previous command routine, now using a function dispatch table.  
By associating command strings with corresponding handler functions,  
it improves both clarity and extensibility in how commands are processed.

### 🧪 Key Features

- Maps command names to handler routines in a lookup table  
- Calls corresponding functions based on user input  
- Easy to add or remove commands modularly

A foundational step toward more maintainable and expandable command logic.
