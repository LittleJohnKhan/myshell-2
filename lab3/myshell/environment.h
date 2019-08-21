/**************************************************************************
 * 名称：           environment.h
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           与环境变量、进程表、umask有关的变量和函数的声明及结构体的定义
**************************************************************************/

#ifndef ENVIRONMENT_H   //environment.h
#define ENVIRONMENT_H

#include "main.h"

//环境变量的结构，包括变量名和变量值
typedef struct envVar
{
    char name[MAX_LENGTH_ENVNAME];
    char value[MAX_LENGTH_COMMAND];
} envVar;

//存储环境变量的起始内存地址的全局变量
extern envVar* envMem;

//初始化环境变量，用于程序起始时
void envInit();
//根据环境变量名计算hash值，用于优化查询，传入参数为变量名
int envHash(char* envName);
//添加环境变量，传入参数为全局变量的名和值
void envAdd(char* envName, char* envValue);
//获取存储该环境变量信息的内存地址，传入参数为变量名，返回指向这段内存的指针
envVar* envAddrGet(char* envName);
//获取环境变量的值，传入参数为变量名，返回指向共享内存中存储该变量值的指针
char* envGet(char* envName);
//用于销毁共享内存
void shmDestroy(int id, void* mem);
//释放分配的内存，用于程序结束时
void envDestroy();

//进程类型的定义，包括前台和后台
typedef enum jobType { FG, BG } jobType;
//进程状态的定义，包括运行和暂停
typedef enum jobStatus { RUN, SUSPEND } jobStatus;
//进程变量的结构，包括pid，进程名，类型，状态，指向前一个和后一个进程的指针
typedef struct job* jobNode;
typedef struct job
{
    pid_t pid;
    char name[MAX_LENGTH_COMMAND];
    jobType type;
    jobStatus status;
    jobNode lastJob;
    jobNode nextJob;
} job;

//进程表的起始地址的全局变量
extern job* jobMem;

//初始化进程表
void jobInit();
//向进程表内添加进程，返回指向该内存段的指针
job* jobAdd(pid_t pid, char* name, jobType type, jobStatus status);
//获取进程表中某一进程的内存地址
job* jobMemAddr(pid_t pid);
//从进程表中删除进程
void jobDel(pid_t pid);

//用于实现管道
extern int pipeFd[2];

//用于实现umask命令
extern int* mask;
//初始化mask变量
void maskInit();

#endif  //environment.h
