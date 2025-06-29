# boot.4.3

## 🗾 概要（Japanese）

1〜100を足すと 5050。そのあと**マジックナンバー30**を足して 5080。  
じゃあこの結果、`INT 0x10` で表示できるかな？と試したら…

**できませんでした (T_T)**

そりゃそうです。  
30 は「1文字分のオフセット」だけど、5080 は「4桁の数字」だから。  
複数桁の表示には、さらなる工夫が必要になります。

というわけで、まずは基本の「2桁表示」から。

たとえば `12` を出したい場合、  
これは `1` と `2` に分解しないといけません。

どうするか？

答えは――**割り算！**

12 ÷ 10 = 商 1, 余り 2


まさに欲しい2桁が出てくる、**小学校4年生の算数**です 😄

ただし、このままだと「余り」が先に得られてしまうため、  
出力は `2 → 1` の**逆順表示**になります。

ま、プロダクトじゃないし。本人が分かってりゃ大丈夫！

---

## 🌐 Overview（English）

Adding the numbers from 1 to 100 gives 5050.  
Then I added a “magic number” of 30 and got 5080.  
I tried printing it via `INT 0x10`… no dice. 😓

Makes sense — 5080 is a four-digit number.  
I’ll need more logic than just adding an ASCII offset.

So I started with something simpler: showing 12.

By dividing 12 by 10:
- Quotient: 1
- Remainder: 2

That gives me the digits I need —  
straight out of 4th grade math 😄

The twist? The remainder comes first.  
So the result shows up as **2 → 1**, instead of 1 → 2.

But hey — it’s not for sale. As long as I know what I’m seeing, that’s good enough.

