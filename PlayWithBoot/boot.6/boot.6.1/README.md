# boot.6.1

## 🗾 概要（Japanese）

ここまでで、以下のことができるようになりました：

- 文字列の出力  
- 数値の表示  
- レジスタの基本的な操作  
- 繰り返し処理  
- ラベルを使った静的な値の参照  
- ディスクリードによるセクタ拡張

──とくれば、あと一歩。

それは、**“外からの入力”に反応すること。**

今回は、キーボードからのキー入力を受け取り、  
その **ASCIIコードを表示** する機能を実装してみました。

これができれば、実験やテストの幅は格段に広がります！

---

## 🌐 Overview（English）

So far, Pax has learned to:

- Print text  
- Display numbers  
- Use registers  
- Perform loops  
- Reference preset values via labels  
- Expand memory range via disk reads

Now… one final step remains:

**Listen to input.**

In this experiment, Pax reads a key from the keyboard  
and prints its **ASCII code** on the screen.

That opens the door to a new kind of freedom —  
the freedom to respond.
