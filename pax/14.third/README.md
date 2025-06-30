# 14.third

## 🗾 概要（Japanese）

タスク構造の再整理とルーチンの見直しを行ったマルチタスク環境です。  
ハンドラタスクを親とし、その中から **子タスク2つ＋孫タスク3つ** を起動・実行しています。  
この階層的なタスク構成は、今後のシステム設計における基本形となる予定です。

### 🧩 主な変更点・特徴

- **tick表示機能**：各タスクが定期的に出力することで、動作状態を視覚的に把握可能  
- **リングバッファ**：シンプルな共有キューを用いて、**各タスク間でのデータ通信**を実現  
- 表示出力が整い、**デモンストレーション用途にも適した構成**に進化

---

## 🌐 Overview（English）

A refined multitasking setup with reorganized task structure and improved routines.  
A handler task spawns two child tasks, which in turn launch three grandchild tasks — forming a hierarchical execution tree.  
This layered task model will serve as the foundational structure for future system designs.

### 🧪 Key Features

- **Tick display**: Each task periodically outputs a tick to make execution progress visually observable  
- **Ring buffer communication**: A simple queue-based mechanism enables basic data exchange between tasks  
- The display is now cleaner and well-organized, making it suitable for demonstration purposes
