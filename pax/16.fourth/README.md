# 16.fourth

## 🗾 概要（Japanese）

子タスクを1つに絞り込み、**タスク間通信に特化**した構成です。

### 📌 主な変更点・特徴

- **キーボード割り込みに対応**：ユーザー入力のたびに割り込みが発生
- 親タスク（ハンドラ）が割り込みを受け、**キーコードをデコード**  
  → キーステータス & ASCII コードとして解釈
- 専用のリングバッファを介して、**子タスクに入力データを送信**
- リングバッファの**先頭状態・送受信データ**を画面に表示

表示の流れによって、各タスクの分担と通信が視覚的にわかるようになっており、  
**マルチタスクが明確に伝わる構成**となっています。

---

## 🌐 Overview（English）

A refined multitasking setup focusing on **inter-task communication**,  
with a single child task operating alongside a keyboard-interrupt-driven parent handler.

### 🧪 Key Features

- **Keyboard interrupt handling**: Triggers on keypresses
- Handler decodes scan codes into **ASCII & key status**
- A **dedicated ring buffer** transmits data from parent to child
- Buffer state, including **head pointer & transmitted data**, is displayed in real time

This program clearly demonstrates multitasking through its communication workflow  
and provides a strong visual representation of cooperative task behavior.
