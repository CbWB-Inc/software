概要：
	x86_64ロングモードの実験コードです。
	UEFI BIOSでブートしてkernelに処理を移すところまでの処理です。
	kernel側は空で何もしていません。
	ブート→必要な情報の取得→	kernelファイルの検索→	kernelファイルの読み込み→kernelへジャンプ
	の順で行っています。


Overview:
	This is experimental code for x86_64 long mode.
	It handles the process of booting via UEFI BIOS and transferring control to the kernel.
	The kernel side is currently empty and does nothing.

	The sequence is as follows:

	Boot
	・Retrieve required system information
	・Locate the kernel file
	・Load the kernel file into memory
	・Jump to the kernel
