/**************************************************************************
 * 名称：           parse.c
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           与命令的解析和执行有关函数的实现
**************************************************************************/

#include "parse.h"
#include "builtin.h"
#include "environment.h"

//处理SIGCHLD信号的结构体及其备份
struct sigaction sig_action;
struct sigaction old_sig_action;

//初始化命令行
void init_commandline()
{
    //初始化信号处理
    signalInit();
    //显示目录名，然后等待输入一行命令并处理
    //当status状态不是run时，退出
    while (!strcmp(envMem[0].value, "run"))
    {
        displayDirName();
        getCommand(stdin);
    }
}

//初始化执行文件
void init_file(char* fileName)
{
    //初始化信号处理
    signalInit();
    //打开文件
    FILE* fp = fopen(fileName, "r");
    if (NULL == fp)
    {
        errorExit("file open", FILE_OPEN_FAILED);
    }
    //从文件中读入一行并进行处理
    //当status状态不是run时，退出
    while (!strcmp(envMem[0].value, "run"))
    {
        //文件全部读完，退出
        if (!getCommand(fp))
            break;
    }
}

//初始化信号处理
void signalInit()
{
    //捕获ctrl-Z信号后，执行ctrlZHandler函数
    signal(SIGTSTP, ctrlZHandler);
    signal(SIGSTOP, ctrlZHandler);

    //将sig_action结构全部清零
    memset(&sig_action, 0, sizeof(sig_action));
    //信号处理函数childExit
    sig_action.sa_sigaction = childExit;
    sig_action.sa_flags = SA_RESTART | SA_SIGINFO;
    sigemptyset(&sig_action.sa_mask);
    //SIGCHLD信号处理
    sigaction(SIGCHLD, &sig_action, &old_sig_action);
}

//捕获SIGCHLD信号执行的函数
void childExit(int sig_no, siginfo_t* info, void* vcontext)
{
    //获取发送信号的进程号
    pid_t pid = info->si_pid;
    //获取该进程在进程表中的信息
    job* jobAddr = jobMemAddr(pid);
    //输出信息
    if (BG == jobAddr->type)
    {
        printf(NORMALSTRING"\n%d\t%s\tend\n", jobAddr->pid, jobAddr->name);
    }
    //将进程从进程表中删除
    jobDel(pid);
    //清空stdin缓冲区
    tcflush(fileno(stdin), TCIFLUSH);
    //开始新的一行，显示当前目录名
    displayDirName();
    //返回，等待读入
    return;
}

//处理crtl-Z信号，将正在运行的进程挂起
void ctrlZHandler(int sig_no)
{
    //获取进程表中第1个进程的信息
    job* suspJob = jobMem[0].nextJob;
    if (suspJob)
    {
        //向该进程发送SIGSTOP信号
        kill(suspJob->pid, SIGSTOP);
        //更新进程表
        suspJob->status = SUSPEND;
        suspJob->type = BG;
        //输出信息
        printf(NORMALSTRING"\n%d\t%s\tsuspend\n", suspJob->pid, suspJob->name);
    }
}

//显示当前目录名
void displayDirName()
{
    //从环境变量pwd读取目录的绝对路径
    char* currentDir = envGet("pwd");
    //获取目录名，新建一个指向字符串结尾的指针
    char* p_dirName = currentDir + strlen(currentDir) - 1;
    //当前目录不是根目录
    if (strlen(currentDir) > 1)
    {     
        //指针向前移动，直到遇到第一个/
        while (*p_dirName != '/')
        {
            --p_dirName;
        }
        ++p_dirName;
    }
    //显示目录名
    printf(BLUESTRING"%s -> "NORMALSTRING, p_dirName);
    //清空stdout缓冲区
    fflush(stdout);
}

//读入命令并解析，传入参数为读取命令的文件
bool getCommand(FILE* fp)
{
    //从文件中读取一行
    char currentCommand[MAX_LENGTH_COMMAND];
    if (fgets(currentCommand, MAX_LENGTH_COMMAND, fp))
    {
        //如果命令为help，直接进行字符串替换
        if (!strcmp(currentCommand, "help\n"))
        {
            strcpy(currentCommand, "cat /usr/local/bin/readme_mysh | more\n");
        }
        //解析命令
        parse(currentCommand);
        return true;
    }
    //读入EOF
    else
    {
        return false;
    }
}

//解析字符串，实现为有限状态机
void parse(char* command)
{
    //新建命令列表
    cmdNode command_list;
    cmdListInit(&command_list);
    cmdNode thisCmd = command_list;
    argNode thisArg;
    //parser状态
    parseStatus status = NEWCMDPRE;
    //状态及控制信号
    bool optionReady = false;
    //以空格和tab为分隔符，分割字符串为单词
    char* word;
    while ((word = strsep(&command, " \t\n")))
    {
        //连续多个空格或tab的情况
        if (0 == strlen(word))
        {
            continue;
        }
        //判断当前状态
        switch (status)
        {
            //准备读取新命令
            case NEWCMDPRE_PIPE:
            case NEWCMDPRE:
                //行首为空格或tab的情况
                if (' ' == *word || '\t' == *word)
                {
                    break;
                }
                //建立新命令节点
                thisCmd = newCmd(thisCmd);
                strcpy(thisCmd->commandName, word);
                thisArg = thisCmd->argList;
                //管道准备接收
                if (NEWCMDPRE_PIPE == status)
                {
                    thisCmd->pipeIn = true;
                }
                //状态转换为正在读取命令
                status = NEWCMDREADY;
                break;
            //正在读取命令
            case NEWCMDREADY:
                //处理特殊符号
                if (1 == strlen(word))
                {
                    //后台运行
                    if ('&' == *word)
                    {
                        thisCmd->isBG = true;
                        status = NEWCMDPRE;
                        break;
                    }
                    //管道
                    else if ('|' == *word)
                    {
                        thisCmd->pipeOut = true;
                        status = NEWCMDPRE_PIPE;
                        break;
                    }
                    //重定向输入
                    else if ('<' == *word)
                    {
                        thisCmd->isInRedirect = COVER;
                        status = INREDIRECTREADY;
                        break;
                    }
                    //重定向输出
                    else if ('>' == *word)
                    {
                        thisCmd->isOutRedirect = COVER;
                        status = OUTREDIRECTREADY;
                        break;
                    }
                }
                //处理特殊符号
                else if (2 == strlen(word))
                {
                    //重定向输入
                    if ('<' == word[0] && '<' == word[1])
                    {
                        thisCmd->isInRedirect = APPEND;
                        status = INREDIRECTREADY;
                        break;
                    }
                    //重定向输出
                    else if ('>' == word[0] && '>' == word[1])
                    {
                        thisCmd->isOutRedirect = APPEND;
                        status = OUTREDIRECTREADY;
                        break;
                    }
                }
                //准备读入选项
                if ('-' == *word)
                {
                    //选项只允许一个字符
                    if (2 != strlen(word))
                    {
                        printf(REDSTRING"illegal option\n"NORMALSTRING);
                        return;
                    }
                    thisArg = newArg(thisArg);
                    thisArg->option = word[1];
                    optionReady = true;
                    break;
                }
                //选项后紧接着参数
                else if (optionReady)
                {
                    strcpy(thisArg->argument, word);
                    optionReady = false;
                    break;
                }
                //没有选项的参数
                else
                {
                    thisArg = newArg(thisArg);
                    strcpy(thisArg->argument, word);
                    break;
                }
            //准备读入重定向输入的文件
            case INREDIRECTREADY:
                strcpy(thisCmd->inFile, word);
                status = NEWCMDREADY;
                break;
            //准备读入重定向输出的文件
            case OUTREDIRECTREADY:
                strcpy(thisCmd->outFile, word);
                status = NEWCMDREADY;
                break;
        }
    }
    thisCmd = command_list;
    //初始化管道
    pipe(pipeFd);
    //逐个命令执行
    while ((thisCmd = thisCmd->nextCmd))
    {
        carryout(thisCmd);
    }
    //销毁命令列表
    commandListDestroy(command_list);
}

//执行命令
void carryout(cmdNode thisCmd)
{
    //建立新进程
    pid_t pid = fork();
    switch (pid)
    {
        case -1:
            errorExit("fork", FORK_FAILED);
        //子进程
        case 0:
        {
            //获取主进程在进程表中建立的进程信息
            usleep(WAIT_TIME);
            job *jobAddr = jobMemAddr(getpid());
            //等待主进程初始化完毕
            while (SUSPEND == jobAddr->status)
            {
                usleep(WAIT_TIME);
            }
            //子进程开始执行命令
            childProcess(thisCmd);
            exit(0);
        }
        //主进程
        default:
        {
            //在进程表中建立新的进程信息
            job *childAddr = jobAdd(pid, thisCmd->commandName, 
                                    (thisCmd->isBG) ? BG : FG, SUSPEND);
            //后台进程输出进程信息
            if (thisCmd->isBG)
            {
                printf("%d\t%s\n", pid, thisCmd->commandName);
            }
            //前台进程
            else
            {
                //SIGCHLD信号处理恢复默认
                sigaction(SIGCHLD, &old_sig_action, NULL);
                //如果从管道读入，主进程关闭管道，以免影响子进程读取
                if (thisCmd->pipeIn)
                {
                    close(pipeFd[0]);
                    close(pipeFd[1]);
                }
            }
            //子进程开始运行
            childAddr->status = RUN;
            //前台进程
            if (!thisCmd->isBG)
            {
                //阻塞
                pause();
                //前台进程结束，在进程表中删除进程信息
                if (RUN == childAddr->status)
                {
                    jobDel(pid);
                }
                //恢复对SIGCHLD信号的捕获和处理
                sigaction(SIGCHLD, &sig_action, NULL);
            }
            //更新umask
            if (*mask < 512)
            {
                umask(*mask);
            }
        }
    }
}

//子进程的行为
void childProcess(cmdNode thisCmd)
{
    //备份旧的stdin/stdout文件描述符
    int oldInFd = dup(fileno(stdin));
    int oldOutFd = dup(fileno(stdout));
    //管道重定向，从管道接收
    if (thisCmd->pipeIn)
    {
        dup2(pipeFd[0], fileno(stdin));
        close(pipeFd[0]);
        close(pipeFd[1]);
    }
    //管道重定向，从管道读取
    if (thisCmd->pipeOut)
    {
        dup2(pipeFd[1], fileno(stdout));
        close(pipeFd[0]);
        close(pipeFd[1]);
    }
    //文件重定向stdin
    switch (thisCmd->isInRedirect)
    {
        case NOREDIRECT:
            break;
        case COVER:
        {
            redirectInit(stdin, thisCmd->inFile, COVER);
            break;
        }
        case APPEND:
        {
            redirectInit(stdin, thisCmd->inFile, APPEND);
            break;
        }
    }
    //文件重定向stdout
    switch (thisCmd->isOutRedirect)
    {
        case NOREDIRECT:
            break;
        case COVER:
        {
            redirectInit(stdout, thisCmd->outFile, COVER);
            break;
        }
        case APPEND:
        {
            redirectInit(stdout, thisCmd->outFile, APPEND);
            break;
        }
    }
    //命令名hash值
    unsigned long long commandNameValue = 0;
    for (int i = 0; thisCmd->commandName[i]; ++i)
    {
        commandNameValue = commandNameValue * 1926 + thisCmd->commandName[i] - 'a';
    }
    //执行命令
    switch (commandNameValue)
    {
        //内建命令，直接调用函数
        case PWD_VALUE:
            command_pwd();
            break;
        case EXIT_VALUE:
            command_exit();
            break;
        case CLEAR_VALUE:
            command_clear();
            break;
        case TIME_VALUE:
            command_time();
            break;
        case ECHO_VALUE:
            command_echo(thisCmd->argList);
            break;
        case CD_VALUE:
            command_cd(thisCmd->argList);
            break;
        case LS_VALUE:
            command_ls(thisCmd->argList);
            break;
        case EXEC_VALUE:
            command_exec(thisCmd->argList);
            break;
        case ENVIRON_VALUE:
            command_environ();
            break;
        case SET_VALUE:
            command_set(thisCmd->argList);
            break;
        case UNSET_VALUE:
            command_unset(thisCmd->argList);
            break;
        case UMASK_VALUE:
            command_umask(thisCmd->argList);
            break;
        case TEST_VALUE:
            command_test(thisCmd->argList);
            break;
        case JOBS_VALUE:
            command_jobs();
            break;
        case SHIFT_VALUE:
            command_shift(thisCmd->argList);
            break;
        case FG_VALUE:
            command_fg();
            break;
        case BG_VALUE:
            command_bg();
            break;
        //外部命令
        default:
        {
            //二维数组，存储参数列表
            char args[MAX_LENGTH_COMMAND][MAX_LENGTH_COMMAND];
            //存储指向每个字符串指针的数组
            char *argp[MAX_LENGTH_COMMAND];
            argNode thisArg = thisCmd->argList;
            int i = 0;
            //数组第一行为调用的文件名
            strcpy(args[i], thisCmd->commandName);
            //将参数列表转换为二维数组
            while ((thisArg = thisArg->nextArg))
            {
                //有选项
                if ('\0' != thisArg->option)
                {
                    sprintf(args[++i], "-%c", thisArg->option);
                }
                //有参数
                if ('\0' != thisArg->argument[0])
                {
                    strcpy(args[++i], thisArg->argument);
                }
            }
            //数组下一行为NULL，表示结束
            argp[++i] = NULL;
            //为指针数组依次赋值
            while (--i >= 0)
            {
                argp[i] = args[i];
            }
            //调用exec族执行外部命令
            execvp(thisCmd->commandName, argp);
            break;
        }
    }
    //恢复文件重定向
    if (NOREDIRECT != thisCmd->isInRedirect)
    {
        redirectEnd(stdin, oldInFd);
    }
    if (NOREDIRECT != thisCmd->isOutRedirect)
    {
        redirectEnd(stdout, oldOutFd);
    }
    //恢复管道重定向
    if (thisCmd->pipeIn)
    {
        dup2(oldInFd, fileno(stdin));
    }
    if (thisCmd->pipeOut)
    {
        dup2(oldOutFd, fileno(stdout));
    }
}

//初始化重定向
void redirectInit(FILE* src, char* fileName, redirecType type)
{
    //按照重定向的方式打开文件
    int fd = 0;
    switch (type)
    {
        case COVER:
            fd = open(fileName, O_RDWR | O_CREAT, 0644);
            break;
        case APPEND:
            fd = open(fileName, O_RDWR | O_APPEND | O_CREAT, 0644);
            break;
        default:
            break;
    }
    //将文件描述符复制到stdin/stdout
    if (-1 == dup2(fd, fileno(src)))
    {
        errorExit("dup", DUP_FAILED);
    }
    //关闭文件描述符
    close(fd);
}

//重定向结束，恢复正常状态，传入重定向的目标和旧的文件描述符备份
void redirectEnd(FILE* dst, int oldFd)
{
    //将旧的文件描述符备份复制到stdin/stdout
    if (-1 == dup2(oldFd, fileno(dst)))
    {
        errorExit("dup", DUP_FAILED);
    }
    //关闭旧的文件描述符
    close(oldFd);
}

//初始化命令链表
void cmdListInit(cmdNode* cmdList)
{
    //为哨兵节点分配内存
    *cmdList = (cmdNode)malloc(sizeof(command));
    if (NULL == *cmdList)
    {
        errorExit("malloc", MALLOC_FAILED);
    }
    (*cmdList)->nextCmd = NULL;
}

//建立新命令节点
cmdNode newCmd(cmdNode cmdListNode)
{
    //为新节点分配内存
    if (NULL == (cmdListNode->nextCmd = (cmdNode)malloc(sizeof(command))))
    {
        errorExit("malloc", MALLOC_FAILED);
    }
    //初始化新节点
    cmdNode newNode = cmdListNode->nextCmd;
    argListInit(&newNode->argList);
    newNode->isInRedirect = NOREDIRECT;
    newNode->isOutRedirect = NOREDIRECT;
    newNode->isBG = false;
    newNode->pipeIn = false;
    newNode->pipeOut = false;
    newNode->nextCmd = NULL;
    return newNode;
}

//销毁命令链表
void commandListDestroy(cmdNode cmdList)
{
    //逐个节点释放
    cmdNode nextCmd;
    while (cmdList)
    {
        nextCmd = cmdList->nextCmd;
        //释放这一命令的参数链表
        argListDestroy(cmdList->argList);
        free(cmdList);
        cmdList = nextCmd;
    }
}

//初始化参数链表
void argListInit(argNode* argList)
{
    //为哨兵节点分配内存
    *argList = (argNode)malloc(sizeof(cmdarg));
    if (NULL == *argList)
    {
        errorExit("malloc", MALLOC_FAILED);
    }
    (*argList)->nextArg = NULL;
}

//建立新参数节点
argNode newArg(argNode argListNode)
{
    //为新节点分配内存
    if (NULL == (argListNode->nextArg = (argNode)malloc(sizeof(cmdarg))))
    {
        errorExit("malloc", MALLOC_FAILED);
    }
    //初始化新节点
    argNode newNode = argListNode->nextArg;
    newNode->option = '\0';
    newNode->argument[0] = '\0';
    newNode->nextArg = NULL;
    return newNode;
}

//销毁参数列表，用于命令执行完毕后
void argListDestroy(argNode argList)
{
    argNode nextArg;
    //逐个节点销毁链表，释放内存
    while (argList)
    {
        nextArg = argList->nextArg;
        free(argList);
        argList = nextArg;
    }
}