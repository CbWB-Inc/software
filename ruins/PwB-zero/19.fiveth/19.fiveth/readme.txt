19.fiveth.6

  メッセージキューを実装しました。
  まだ不安定ですが一通り動くようになっています。
  これにより各タスク間で双方向のメッセージのやり取りが可能になりました。
  でも機能としてp_taskから他のタスクへメッセージを送りそれを表示しています。
  データは1ワードであるほかに制限がないので、実行優先度の調子など様々な場面で使うことができます。
  現状は素朴な構造なので今後は折を見て機能拡張もしたいところです。



  Message Queue Implementation

  A message queue has been implemented.
  While it's still somewhat unstable, it's now functioning end-to-end.
  This enables bidirectional messaging between tasks.

  Currently, the system allows `p_task` to send messages to other tasks, and those tasks can then display the received messages.

  There are no major restrictions aside from the message being limited to a single word of data, which makes it versatile for various situations — such as coordinating execution priorities and other runtime behaviors.

  Although the structure is still quite minimalistic, future extensions and refinements are planned as opportunities arise.
