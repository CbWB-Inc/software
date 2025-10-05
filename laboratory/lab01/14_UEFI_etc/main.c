#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"


extern uint32_t* fb;
extern uint32_t _c_y, _c_x, _color, _pitch;

uint64_t xorshift64(void);
uint64_t xorshift64o(void);
uint64_t xorshift64w(void);
int rdrand64(uint64_t *out);
double rand(void);
void clsfb();

void main(){

    _color = 0x000000;
    clsfb();
    _color = 0xffffff;

    // xorshift64による乱数
    // 系列を変えたい時はグローバル変数xs_stateに
    // 望みの数値を入れてください。
    
    uint64_t xs_state = 88172645463325252ull;
    ps("xorchift64による乱数その１\n");
    for (int i=0; i<10; i++) {
        ps("  ");
        ps("0x");ph16(xorshift64());
        pc('\n');
    }
    pc('\n');pc('\n');

    xs_state = 88172645463325252ull;
    ps("xorchift64による乱数その２\n");
    for (int i=0; i<10; i++) {
        ps("  ");
        ps("0x");ph16(xorshift64o());
        pc('\n');
    }
    pc('\n');pc('\n');
    
    xs_state = 88172645463325252ull;
    ps("xorchift64(Wikipedia版)による乱数\n");
    for (int i=0; i<10; i++) {
        ps("  ");
        ps("0x");ph16(xorshift64w());
        pc('\n');
    }
    pc('\n');pc('\n');
    
    // 高々10回ずつ回しただけでどうこう言うのは片腹痛いのだけれど
    // uint64_tで定義はしてあるものの正負込みの32Bit値であるらしいですね。
    // もっと大量に回すなら状況は変わるかもしれません。
    // ただ、回数限定の普段使いするとしたら十分じゃないかと。
    // シフトパラメータを変えると傾向も変わるので
    // 気になる方はよさげな数値に書き換えて使ってください。


    ps("H/W乱数\n");
    uint64_t x;
    for (int i=0; i<10; i++) {
        ps("  ");
        rdrand64(&x);
        ps("0x");ph(x);pc('\n');
    }
    pc('\n');pc('\n');

    // 散らばり具合は良好のようです。
    // ただしゲストOSからエミュレータを介して使っているため
    // 純粋のH/Wではなくどこかでエミュレートされた値かもしれません。
    // 実機で動かすならともかく、開発環境と同じ環境で使う場合、心に留めておく必要があります。
    // 純粋なH/W乱数であるなら、同一の値には一生巡り合えないと思います。    
    // （それはそれで困ることも多いのですけれどもね）
    
    ps("H/W乱数：1万未満の数\n");
    for (int i=0; i<10; i++) {
        ps("  ");
        double y = (rand() * 10000) ;
        (y<0)?y*(-1):y;
        pd((uint32_t)y);pc('\n');
    }
    pc('\n');pc('\n');
    
    // 追記
    // 1未満を返すrdand、それを正規化したrandも用意してはあるのですが
    // 現状実数の表示系を作ってないので試していません。
    // ともあれ32Bit値以下で使うなら問題ないと思っています。
    // MTはどうしたという向きもあるかもしれませんが
    // 面倒だったので用意していません。    


    // __asm__ volatile("sti");  

    for(;;) __asm__ __volatile__("hlt");
}


