# 08.far

## 🗾 概要（Japanese）

共通ルーチンを far call 対応させようとした試みです。  
これまで near call のみ対応だったため、セグメントをまたいだ呼び出しは不可能でした。  
しかし、ルーチンや機能が増えたことで、セグメントを跨ぐ構造が必然になってきたため、  
共通ルーチン自体も far call 対応を目指すことになりました。

### 📌 結果と判断

- 実装を試みるも、パラメータ管理に大きな制約（レジスタ4本では引数不足）  
- 実際に運用すると far call はかえって煩雑になるケースが多発  
- 結果的に、各タスクごとに独自に共通ルーチンを持つ形へシフト

構造的には合理的だったものの、実用面・呼び出し制御の面から断念した形です。  
それでも、設計選択を試行錯誤した経験は次の構造設計に活かされています。

---

## 🌐 Overview（English）

An experiment aimed to make shared routines callable via far call.  
Previously, only near calls were supported,  
which made it impossible to invoke routines across segments.

As the number of features and routines grew,  
cross-segment organization became inevitable—  
prompting an attempt to adapt the routines accordingly.

### 🧪 Outcome & Decision

- The implementation exposed serious limitations in parameter passing  
  (four general-purpose registers were often not enough)  
- In practice, using far calls led to more complexity than it solved  
- Ultimately, each task was given its own copy of the routines instead

Though structurally sound, the approach was abandoned for practicality.  
The process itself, however, became a valuable exploration in architectural boundaries.
