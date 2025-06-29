# boot.4.4

## 🗾 概要（Japanese）

2桁の数値を文字として表示する原理がわかったので──  
いざ、1〜100までの合計「5050」の出力にリベンジです！

4桁の数値は、次のようにして10進の各桁に分けられるはず：

1. 5050 ÷ 10 → 余り = 0（表示）
2. 505 ÷ 10 → 余り = 5（表示）
3. 50 ÷ 10 → 余り = 0（表示）
4. 5 ÷ 10 → 余り = 5（表示）

→ 出力順は `0 → 5 → 0 → 5`、つまり **逆順表示**。

でも、**自分がわかっていればOK！**  
いまは「数字を出す力を得た」ことがなにより大事ですね 😊

---

## 🌐 Overview（English）

Now that I’ve figured out how to display two-digit numbers,  
it’s time to revisit the sum of 1 through 100 — **5050**.

To display a four-digit number, I use the classic divide-and-mod pattern:

1. 5050 mod 10 → 0
2. 505 mod 10 → 5
3. 50 mod 10 → 0
4. 5 mod 10 → 5

→ Output sequence: `0 → 5 → 0 → 5` (in reverse)

Sure, it’s backward. But as long as I understand what I’m seeing, it’s totally fine! 😄
