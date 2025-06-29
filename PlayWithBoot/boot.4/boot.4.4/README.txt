boot.4.4

  さて、二桁の数値を表示する原理が分かったところで
  1～100までの合計である5050にリベンジです。
  4桁ですから10で割って余りを表示ってのを
  4回やれば表示できるはずです。
  10で割った余りを表示
  答えを10で割って余りを表示
  それまた答えを10で割って余りを表示
  最後に答えを10で割って余りを表示
  表示順は0→5→0→5となります。
  逆順ですけどわかってるから無問題♪


boot.4.4

  Now that I understand how to display two-digit numbers,
  it’s time to take another shot at displaying the sum of 1 through 100: 5050.

  It’s four digits — so if I use mod 10 and div 10 repeatedly,
  I should be able to break it down and print each digit.

  Here’s the plan:

    - Take 5050 → mod 10 → print remainder
    - Divide result by 10 → mod 10 → print
    - Again → divide by 10 → mod 10 → print
    - One last time → divide by 10 → mod 10 → print

  That gives me: 0 → 5 → 0 → 5

  It’s backwards, sure. But I get it — so no problem! 😄

