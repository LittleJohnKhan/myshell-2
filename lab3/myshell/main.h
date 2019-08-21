/**************************************************************************
 * 名称：           main.h
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           包含所需的函数库和系统调用
**************************************************************************/

#ifndef MAIN_H
#define MAIN_H

//系统调用
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/shm.h>
#include <sys/stat.h>

//标准库
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <limits.h>
#include <stdbool.h>
#include <signal.h>

//该shell程序的名称
#define SHELLNAME "mysh"

//错误代码的宏定义
#define FILE_OPEN_FAILED 200
#define MALLOC_FAILED 201
#define FORK_FAILED 202
#define OPENDIR_FAILED 203
#define CD_FAILED 204
#define SHMGET_FAILED 205
#define SHMAT_FAILED 206
#define SHMDT_FAILED 207
#define SHMCTL_FAILED 208
#define DUP_FAILED 209

//程序运行时允许的最大值，用于分配内存
//环境变量的最多个数
#define MAX_ENVVAR 64
//环境变量的最大长度
#define MAX_LENGTH_ENVNAME 16
//单个命令的最大长度
#define MAX_LENGTH_COMMAND 256
//最多同时运行的进程数
#define MAX_JOB 8
//路径名的最大长度
#ifndef _POSIX_PATH_MAX
#define _POSIX_PATH_MAX 256
#endif

//等待时每次轮询的暂停时间，单位为毫秒
#define WAIT_TIME 500

//用于控制终端输出的颜色
#define REDSTRING "\033[31m"
#define YELLOWSTRING "\033[33m"
#define PURPLESTRING "\033[35m"
#define BLUESTRING "\033[36m"
#define NORMALSTRING "\033[0m"

//用于显示错误信息并退出程序
void errorExit(char *procName, int errorNo);

//用于调试输出
void debug(int i);

#endif