/**************************************************************************
 * 名称：           main.c
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           主函数的实现
**************************************************************************/

#include "parse.h"
#include "environment.h"

//主函数
int main(int argc, char* argv[])
{
    //初始化运行环境
    envInit();
    //无参数传入，进入命令行模式
    if (1 == argc)
    {
        init_commandline();
    }
    //有参数传入，运行脚本文件
    else
    {
        init_file(argv[1]);
    }
    //结束运行环境
    envDestroy();
}

//严重错误的处理，以红色字体向stderr中输出错误信息，并退出程序
void errorExit(char *procName, int errorNo)
{
    fprintf(stderr, REDSTRING"%s failed\n"NORMALSTRING, procName);
    exit(errorNo);
}

//用于调试，输出"debug"和整数i
void debug(int i)
{
    fprintf(stderr, REDSTRING"debug%d\n"NORMALSTRING, i);
}