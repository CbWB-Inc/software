# 11.second

## 🗾 概要（Japanese）

前章 `10.tiny_tss` の TSS 実装をもとに、タスク構成の見直しと改変を行った試作です。  
**タスク1 とタスク2 を 3:1 の比率で切り替えて実行する設計**が特徴です。

### 📌 特徴

- TSSベースの割り込み処理によるタスクスイッチング  
- タスクごとに異なる実行頻度を設定（比率制御）  
- スケジューラ構造の導入実験

### 🚧 状態と課題

- 一見動作しているように見えるが、内部には未修正の不具合が残存  
- 状況によって不安定になることがあり、挙動が完全には読みきれない  
- とはいえ「不均等スケジューリング」の実装例として重要な一章

---

## 🌐 Overview（English）

A continuation of the previous `10.tiny_tss` experiment, this version reorganizes the task structure  
with an emphasis on **executing Task 1 and Task 2 in a 3:1 ratio**.

### 🧪 Highlights

- TSS-based task switching via hardware interrupts  
- Implements unequal execution frequency between tasks  
- Initial experiment with scheduler-like control logic

### ⚠️ Current State

- Appears to function but still contains bugs beneath the surface  
- Behavior may become unstable under certain conditions  
- Nonetheless, this marks a key step toward uneven task scheduling and real-time behavior simulation
