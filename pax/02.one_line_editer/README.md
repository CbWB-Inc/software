# 02.one_line_editter

## 🗾 概要（Japanese）

1行だけの編集機能を持った echo プログラムです。  
左右方向キーでカーソルを移動し、通常の文字キー入力でその位置に上書きします。  
リターンキーを押すと、**行頭からカーソル位置までの内容を返す仕様**になっています。

### 📌 機能概要

- 1行限定の軽量エディタロジック  
- 左右方向キーによるカーソル移動  
- 通常キーで文字の上書き入力  
- リターンで確定・出力

### 🚧 制限事項

- Backspace（BS）と Delete キーには未対応  
- それでも用途によっては十分機能します

テスト用UIや最小限のプロンプト入力など、シンプルな操作系を要する場面に有効です。

---

## 🌐 Overview（English）

A one-line echo program with basic editing functionality.  
The user can move the cursor using the left/right arrow keys and overwrite characters with standard key presses.  
Pressing the Return key will output the content from the beginning of the line up to the current cursor position.

### 🧪 Features

- Minimal editor logic (single-line only)  
- Cursor movement using ← → keys  
- In-place overwriting of characters  
- Return key submits the line segment

### ⚠️ Limitations

- Does not handle Backspace or Delete keys  
- Still suitable in cases where lightweight interaction is preferred

Ideal for prompt-style input or testing UI logic in controlled conditions.

---
