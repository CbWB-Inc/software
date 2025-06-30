# 19.fiveth

## 🗾 概要（Japanese）

タスクの役割を整えました。  
子タスクとして `p_task`, `d_task`、孫タスクとして `k_task1`〜`k_task3` の5タスク構成になりました。

キーボードハンドラで行っていたキーコードのデコードをやめ、キーコードを送るだけに専念させました。  
`p_task` はそれを受け取りデコードし、キーバッファに格納します。  
`k_task1` はバッファからASCIIデータを取り出し、画面に表示します。

また、各タスクの稼働状態を確認する**簡易監視機構**を実装しました。  
さらに、タイマ割り込みの周期を調整することで、システム全体の動作安定性が向上しています。

なんとなく、OSっぽくなってきました。

---

## 🌐 Overview（English）

This version organizes the roles of each task and finalizes a **five-task structure**:  
two child tasks (`p_task`, `d_task`) and three grandchild tasks (`k_task1` to `k_task3`).

The keyboard interrupt handler has been simplified to **send only keycodes**,  
leaving the decoding process to `p_task`, which stores the result into a key buffer.  
Then, `k_task1` retrieves the decoded ASCII input from the buffer and displays it on the screen.

A **basic monitoring mechanism** for task activity has also been implemented,  
and the **timer interrupt cycle** was tuned to improve overall system responsiveness.

It’s starting to resemble a true operating system — just a little more each time.
