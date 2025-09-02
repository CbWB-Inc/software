概要：
    x86_64ロングモードの実験コードです。
    ロングモードに制御を移した後、なにか例外が起きると落ちます。
    何が起きたかわからないうちにサクッと落ちます。
    これだと作業に差し障るので、例外ハンドラを用意して、
    一歩だけ踏みとどまるようにしました。


Here’s the English version of that overview:

Overview:
    This is experimental code for x86_64 long mode.
    After transferring control to long mode, if any exception occurs, the system simply crashes.
    It fails immediately before you can even tell what happened.
    Since this disrupts development, I added basic exception handlers so the system can pause for a moment 
    instead of crashing outright.
