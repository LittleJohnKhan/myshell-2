/**************************************************************************
 * 名称：           parse.h
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           与命令解析与执行有关的函数声明和结构体定义
**************************************************************************/

#ifndef PARSE_H
#define PARSE_H

#include "main.h"

//内建命令hash值的宏定义
#define PWD_VALUE 55684515
#define EXIT_VALUE 28663136479
#define CLEAR_VALUE 27599028185609
#define TIME_VALUE 135774263668
#define ECHO_VALUE 28585235552
#define CD_VALUE 3855
#define LS_VALUE 21204
#define EXEC_VALUE 28663128758
#define ENVIRON_VALUE 1603339966545515189
#define SET_VALUE 66778291
#define UNSET_VALUE 275297188529899
#define UMASK_VALUE 275289977335510
#define TEST_VALUE 135759437335
#define BG_VALUE 1932
#define FG_VALUE 9636
#define JOBS_VALUE 64351991592
#define SHIFT_VALUE 247733860343257

//parser的状态定义，有限状态机
typedef enum parseStatus { 
    NEWCMDPRE, NEWCMDPRE_PIPE, NEWCMDREADY, 
    INREDIRECTREADY, OUTREDIRECTREADY } parseStatus;

//重定向类型的定义
typedef enum redirecType { NOREDIRECT, COVER, APPEND } redirecType;

//参数链表的结构体定义，包括option，argument和指向下一个参数的指针
typedef struct cmdarg* argNode;
typedef struct cmdarg
{
    char option;
    char argument[MAX_LENGTH_COMMAND];
    argNode nextArg;
} cmdarg;

//命令链表的结构体定义
typedef struct command* cmdNode;
typedef struct command
{
    //命令名
    char commandName[MAX_LENGTH_COMMAND];
    //参数列表
    cmdarg* argList;
    //是否是后台运行
    bool isBG;
    //是否用管道
    bool pipeIn;
    bool pipeOut;
    //重定向类型
    redirecType isInRedirect;
    redirecType isOutRedirect;
    //重定向的文件名
    char inFile[MAX_LENGTH_COMMAND];
    char outFile[MAX_LENGTH_COMMAND];
    //指向下一个命令的指针
    cmdNode nextCmd;
} command;

//初始化命令行
void init_commandline();
//初始化执行脚本文件
void init_file(char* fileName);
//显示当面目录的名称，用于命令行下
void displayDirName();
//从文件（包括stdin）获取一行输入
bool getCommand(FILE* fp);
//解析一行输入，传入输入的字符串
void parse(char* command);
//执行一系列命令，传入参数列表
void carryout(cmdNode cmdList);
//执行命令时建立子进程，传入单个命令节点
void childProcess(cmdNode thisCmd);

//初始化命令列表，用于开始解析一行输入时，传入二级指针
void cmdListInit(cmdNode* cmdList);
//新建命令，传入命令节点，直接在下一个节点新建命令
cmdNode newCmd(cmdNode cmdList);
//销毁命令
void commandListDestroy(cmdNode cmdList);

//初始化参数列表，用于新建命令时，传入二级指针
void argListInit(argNode* argList);
//新建参数，传入参数节点，直接在下一个节点新建参数
argNode newArg(argNode argListNode);
//销毁参数列表
void argListDestroy(argNode argList);

//初始化重定向，src为被重定向的文件指针（stdin/stdout），fileName为重定向的文件名
//用于执行命令时
void redirectInit(FILE* src, char* fileName, redirecType type);
//结束重定向，恢复正常状态
void redirectEnd(FILE* dst, int oldFd);

//初始化信号处理
void signalInit();
//信号处理函数，用于处理接收到SIGCHLD信号
void childExit(int sig_no, siginfo_t* info, void* vcontext);
//信号处理函数，用于处理接收到ctrl-Z信号
void ctrlZHandler(int sig_no);

#endif