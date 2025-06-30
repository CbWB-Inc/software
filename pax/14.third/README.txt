14.third

  タスク構造を整理しました。
  また、ルーチンも見直しました。
  ハンドラから子タスク2つ、孫タスク3つが起動され動いています。
  このタスク構造は今後のベースとなります。
  tickを実装して各タスクが表示することでそれぞれのタスクが動いていることがわかるようになりました。
  リングバッファを使った簡易データ通信を実装し、各タスク間でデータをやり取りできるようになっています。
  表示系がすっきりしたのでデモとしても使えるものになりました。


  The task structure has been reorganized.
  Routines were also reviewed.
  Two child tasks and three grandchild tasks are launched from the handler.
  This task structure will become the foundation going forward.
  By implementing a tick, each task can display activity to indicate it's running.
  A ring buffer enables simple data communication between tasks.
  The visual output is clean, making it suitable as a demonstration.

