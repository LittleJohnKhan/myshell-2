/**************************************************************************
 * 名称：           builtin.h
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           执行内建命令所调用函数的声明
**************************************************************************/

#ifndef BUILTIN_H   //builtin.h
#define BUILTIN_H

#include "parse.h"

//以下为执行内建命令所调用的函数，函数名格式为command_[commandName]，传入参数列表
//为统一接口，再添加新命令时，传入参数一律为argNode argList
void command_pwd();
void command_time();
void command_exit();
void command_clear();
void command_environ();
void command_jobs();
void command_fg();
void command_bg();
void command_ls(argNode argList);
void command_echo(argNode argList);
void command_cd(argNode argList);
void command_exec(argNode argList);
void command_set(argNode argList);
void command_unset(argNode argList);
void command_umask(argNode argList);
void command_test(argNode argList);
void command_shift(argNode argList);

#endif  //builtin.h