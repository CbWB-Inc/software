08.far

  共通ルーチンをfar callに対応させようとしました。
  これまでの共通ルーチンはnear callしかできなかったので
  セグメントの異なる場所からは呼べませんでした。
  ルーチンも機能も色々増えてセグメントをまたぐことが自明になってきたので
  ルーチンもそれに対応しようと考えたのです。
  ですが、色々実験して紆余曲折の末、far callは諦めることに。
  各タスクが身内に共通ルーチンを持つ形に落ち着きました。
  端的に言ってパラメータが足りなかったのです。
  レジスタ4本では引数が足りない場面が多々あって
  far call対応したほうが煩わしくなったのでした。


  Tried to make common routines compatible with far call.
  Previously, only near call was possible for shared routines.
  They couldn't be called from other segments.
  As routines and features increased, cross-segment use became necessary.
  Ultimately gave up on far call.
  Settled on giving each task its own local version of shared routines.
  With only four registers, arguments were often insufficient.
  Supporting far call became more troublesome as a result.
