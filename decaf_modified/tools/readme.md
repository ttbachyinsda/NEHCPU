1. 将intrinsic.c和entry.s放置在/ucore/user/libs下
2. 将/test/decaffile目录下的blackjack.s、fibonacci.s和math.s放置在/ucore/user下
3. 使用user.ld将上述三个.s文件中的一个和intrinsic.c和entry.s进行链接即可得到能够在CPU上跑的程序