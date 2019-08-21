/**************************************************************************
 * 名称：           builtin.c
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           内建命令所调用函数的实现
**************************************************************************/

#include "builtin.h"
#include "parse.h"
#include "environment.h"

//pwd命令的实现，显示当前工作目录的绝对路径
void command_pwd()
{
    //从环境变量表中获取名为pwd的变量值并输出
    char *currentDir = envGet("pwd");
    printf("%s\n", currentDir);
}

//time命令的实现，显示当前时刻的时间
void command_time()
{
    //获取当前时间并转换为字符串输出
    time_t currentTime = time(NULL);
    printf("%s", ctime(&currentTime));
}

//cd命令的实现，切换工作目录，如果没有传入参数，执行pwd
void command_cd(argNode argList)
{
    //第一个参数为切换到的目录
    if (argList->nextArg)
    {
        //获取新目录
        char *newDir;
        newDir = argList->nextArg->argument;
        //系统调用，切换工作目录
        if (chdir(newDir))
        {
            errorExit("change directory", CD_FAILED);
        }
        else
        {
            //切换成功，更新环境变量
            getcwd(envGet("pwd"), _POSIX_PATH_MAX);
        }
    }
    //没有传入参数，执行pwd
    else
    {
        command_pwd();
    }
}

//echo命令的实现，输出若干字符串，输出的字符串之间一律以一个空格分隔
void command_echo(argNode argList)
{
    //获取参数列表，遍历输出
    argNode thisArg = argList;
    while ((thisArg = thisArg->nextArg))
    {
        printf("%s ", thisArg->argument);
    }
    printf("\n");
}

//clear命令的实现，清屏
void command_clear()
{
    //直接输出屏幕控制符，实现清除屏幕
    printf("\033[2J\033[0;0H");
}

//exit命令的实现，退出程序
void command_exit()
{
    //设置第0个环境变量的值为exit，父进程处理
    strcpy(envMem[0].value, "exit");
}

//ls命令的实现，列出当前目录下的所有文件
void command_ls(argNode argList)
{
    //第1个参数为目录，如果没有参数，则为当前目录
    char* dirName = argList->nextArg ? argList->nextArg->argument : envGet("pwd");
    //打开目录
    DIR* dp = opendir(dirName);
    if (!dp)
    {
        errorExit("directory open", OPENDIR_FAILED);
    }
    //读取目录
    struct dirent *dirp;
    while ((dirp = readdir(dp)))
    {
        //忽略隐藏文件
        if ('.' == dirp->d_name[0])
        {
            continue;
        }
        //根据文件类型以不同颜色输出
        switch (dirp->d_type)
        {
            //普通文件，黄色
            case DT_REG:
                printf(YELLOWSTRING"%s\n"NORMALSTRING, dirp->d_name);
                break;
            //目录文件，蓝色
            case DT_DIR:
                printf(BLUESTRING"%s\n"NORMALSTRING, dirp->d_name);
                break;
            //符号链接，紫色
            case DT_LNK:
                printf(PURPLESTRING"%s\n"NORMALSTRING, dirp->d_name);
                break;
            //其他文件
            default:
                printf("%s\n", dirp->d_name);
        }
    }
    //关闭目录
    closedir(dp);
    //清空stdout缓冲区
    fflush(stdout);
}

//exec命令的实现，执行命令然后退出shell
void command_exec(argNode argList)
{
    //参数列表为新命令
    if (argList->nextArg)
    {
        //新建命令节点
        cmdNode newCmd;
        cmdListInit(&newCmd);
        //第1个参数为命令名
        strcpy(newCmd->commandName, argList->nextArg->argument);
        //后续参数为新命令的参数
        argListInit(&newCmd->argList);
        newCmd->isInRedirect = NOREDIRECT;
        newCmd->isOutRedirect = NOREDIRECT;
        newCmd->isBG = false;
        newCmd->argList->nextArg = argList->nextArg->nextArg;
        newCmd->nextCmd = NULL;
        //执行命令
        carryout(newCmd);
        //执行完命令后，退出shell
        command_exit();
    }
}

//environ命令的实现，列出所有环境变量
void command_environ()
{
    //遍历环境变量表
    for (int i = 0; i < MAX_ENVVAR; ++i)
    {
        if (*envMem[i].name)
            printf("%s=%s\n", envMem[i].name, envMem[i].value);
    }
}

//set命令的实现，设置环境变量，如果没有参数执行environ
void command_set(argNode argList)
{
    //如果没有参数，执行environ
    if (!argList->nextArg)
    {
        command_environ();
        return;
    }
    //第一个参数为变量名，第二个参数为变量值
    char* envName = argList->nextArg->argument;
    if (!*envName)
    {
        return;
    }
    //获取变量所在的地址
    envVar* envAddr = envAddrGet(envName);
    //如果该环境变量已经存在，更新其值
    if (envAddr)
    {
        strcpy(envAddr->value, argList->nextArg->nextArg->argument);
    }
    //如果该环境变量不存在，添加环境变量
    else
    {
        envAdd(envName, argList->nextArg->nextArg->argument);
    }
}

//unset命令的实现，删除环境变量
void command_unset(argNode argList)
{
    //如果参数为空，直接返回
    if (!argList->nextArg)
    {
        return;
    }
    //第1个参数为环境变量的名
    char* envName = argList->nextArg->argument;
    if (!*envName)
    {
        return;
    }
    //status和pwd变量受保护，禁止删除
    if (!strcmp(envName, "pwd") || !strcmp(envName, "status"))
    {
        return;
    }
    //获取环境变量的地址
    envVar* envAddr = envAddrGet(envName);
    //如果没有这一变量，直接返回
    if (!envAddr)
    {
        return;
    }
    //将环境变量表中的结构体清零
    *envAddr->name = 0;
    *envAddr->value = 0;
}

//umask命令的实现，设置umask值
void command_umask(argNode argList)
{
    //第1个参数为mask值
    char* mask_str = argList->nextArg->argument;
    //将八进制字符串形式的mask值转换为mode_t型整数，存储于共享内存中
    *mask = (mode_t)strtol(mask_str, NULL, 8);
}

//test命令的实现，用于测试判断条件是否成立
void command_test(argNode argList)
{
    //从第1个参数中读入选项
    char option = argList->nextArg->option;
    switch (option)
    {
        //n选项，判断字符串是否不空
        case 'n':
            if (strlen(argList->nextArg->argument))
            {
                printf("true\n");
            }
            else
            {
                printf("false\n");
            }
            break;
        //z选项，判断字符串是否为空
        case 'z':
            if (!strlen(argList->nextArg->argument))
            {
                printf("true\n");
            }
            else
            {
                printf("false\n");
            }
            break;
    }
}

//shift命令的实现，从标准输入读入字符串，将读入的参数左移输出，一般用在管道中
void command_shift(argNode argList)
{
    //第一个参数为左移的位数
    int shift = atoi(argList->nextArg->argument);
    //从标准输入读入字符串
    char line[MAX_LENGTH_COMMAND];
    char* line_p = line;
    fgets(line, MAX_LENGTH_COMMAND, stdin);
    //左移，以空格和tab分隔
    for (int i = 0; i < shift; ++i)
    {
        //忽略连续的空格和tab
        while (' ' == *line_p || '\t' == *line_p)
        {
            ++line_p;
        }
        strsep(&line_p, " \t\n");
    }
    //输出新字符串
    while (' ' == *line_p || '\t' == *line_p)
    {
        ++line_p;
    }
    printf("%s", line_p);
}

//jobs命令的实现，输出所有后台进程的信息
void command_jobs()
{
    //遍历进程表
    for (int i = 1; i < MAX_JOB; ++i)
    {
        if (jobMem[i].pid && BG == jobMem[i].type)
        {
            //输出正在运行的后台进程
            if (RUN == jobMem[i].status)
            {
                printf("%d\t%s\trunning\n", jobMem[i].pid, jobMem[i].name);
            }
            //输出挂起的进程
            else
            {
                printf("%d\t%s\tsuspend\n", jobMem[i].pid, jobMem[i].name);
            }
        }
    }
}

//fg命令的实现，将后台进程转入前台
void command_fg()
{
    //获取进程表的第1个进程
    job* bgJob = jobMem[0].nextJob->nextJob;
    //判断后台进程是否存在
    if (bgJob)
    {
        //输出进程信息
        printf("%d\t%s\trunning\n", bgJob->pid, bgJob->name);
        //阻塞，等待进程退出信号
        while (true);
    }
    //后台进程不存在
    else
    {
        printf("no current job\n");
    }
}

//bg命令的实现，将挂起的进程转为后台运行
void command_bg()
{
    //遍历进程表，查找挂起的进程
    for (int i = 1; i < MAX_JOB; ++i)
    {
        //判断是否为挂起的进程
        if (jobMem[i].pid && BG == jobMem[i].type && SUSPEND == jobMem[i].status)
        {
            //更新进程表信息
            jobMem[i].status = RUN;
            //发送继续执行信号
            kill(jobMem[i].pid, SIGCONT);
            //输出进程信息
            printf("%d\t%s\trunning\n", jobMem[i].pid, jobMem[i].name);
        }
    }
}
