# boot.4.5

## 🗾 概要（Japanese）

5050に、ついにリベンジ成功しました！🎉

でもそのときふと……  
おしりのあたり？おなかのあたり？がムズムズする感覚が。

それはたぶん、「同じような処理を何度も書いてる」せいです。  
ちょっとずつ違うけど、パターンは同じ。

──「めんどうくさい」

なので考えました。**まとめよう。**

4桁なら4回繰り返せば表示できるけれど、  
どうせなら、**2桁でも5桁でも動く仕組み**がほしい。

というわけで：

- 10で割って余りを表示
- 答えを10で割って、また余りを表示
- 答えが 0 になるまで繰り返す！

これで、どんな桁数でも数字を出せるようになりました。  
もう、表示のたびにコードを増やす必要はありません。

安心して実験できます！  
**やったね♪**

---

## 🌐 Overview（English）

Finally, sweet revenge against 5050 — complete! 🎉

But while writing the code, I noticed a familiar itch…  
A subtle tension — like something wasn’t quite right.

The culprit?  
**The same logic, repeated multiple times with tiny variations.**

So I paused and thought: “This is getting tedious.”  
And I decided to clean it up.

If it’s 4 digits, sure — repeat 4 times.  
But what if it's 2 digits? Or 5?

So I made it dynamic:

- Keep dividing by 10
- Each time, print the remainder
- Stop when the result hits 0

Now it works for any number of digits!

I can experiment freely — and trust what I see.  
**Mission complete!**
