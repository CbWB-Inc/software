# 0a.mouse

## 🗾 概要（Japanese）

BIOS割り込み経由でマウスを認識し、  
カーソルに追従させようとした試験コードです。

ただしこの時点では解像度が非常に粗く、  
滑らかな動作には程遠いため実用には至りませんでした。

### 📌 目的と現状

- BIOSベースでのPS/2マウス入力の取得
- マウスの移動情報を取得し、カーソルを同期させる
- 期待した滑らかさには届かず、調整は保留中

📝「いつかきっと、復活させるつもりです」

---

## 🌐 Overview（English）

This experimental code attempted to detect mouse input using BIOS interrupts  
and synchronize the cursor movement accordingly.

However, the resolution was far too coarse,  
and the result was not usable in a practical sense.

### 🧪 Goals & Notes

- Receive PS/2 mouse data via BIOS routines  
- Move the cursor based on relative mouse input  
- Implementation was unstable and visually jumpy

_A future revisit is definitely on the list._
