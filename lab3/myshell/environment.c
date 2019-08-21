/**************************************************************************
 * 名称：           environment.c
 * 作者：           吴同
 * 学号：           3170104848
 * 内容：           运行环境有关函数的实现，包括环境变量表，进程表
**************************************************************************/

#include "environment.h"

//共享内存，环境变量表
int envShmID;
envVar* envMem;

//共享内存，进程表
int jobShmID;
job* jobMem;

//共享内存，mask值
int maskShmID;
int* mask;

//用于管道的实现
int pipeFd[2];

//初始化环境
void envInit()
{
    //创建共享内存，获取共享内存标识符
    //如果共享内存创建失败，标识符返回为-1
    if (-1 == (envShmID = shmget((key_t)1926, sizeof(envVar) * MAX_ENVVAR, 0666 | IPC_CREAT)))
    {
        errorExit("shmget", SHMGET_FAILED);
    }
    //将共享内存连接到进程的地址空间
    //如果共享内存连接失败，返回地址为-1
    if ((void*)-1 == (envMem = shmat(envShmID, NULL, 0)))
    {
        errorExit("shmat", SHMAT_FAILED);
    }
    //初始化环境变量表，全部置0
    memset(envMem, 0, sizeof(envVar) * MAX_ENVVAR);

    //环境变量表第0位保留，存储shell程序运行状态
    strcpy(envMem[0].name, "status");
    strcpy(envMem[0].value, "run");

    //初始化pwd变量
    char currentDir[_POSIX_PATH_MAX];
    getcwd(currentDir, _POSIX_PATH_MAX);
    envAdd("pwd", currentDir);
    envAdd("shell", "/usr/local/bin"SHELLNAME);

    //初始化进程表
    jobInit();
    //初始化mask变量
    maskInit();
}

//添加环境变量，传入参数为环境变量的名和值
void envAdd(char* envName, char* envValue)
{
    //获取hash值
    int envNameHash = envHash(envName);
    while (*envMem[envNameHash].name)
    {
        ++envNameHash;
    }
    //将变量名和值存入共享内存
    strcpy(envMem[envNameHash].name, envName);
    strcpy(envMem[envNameHash].value, envValue);
}

//获取存储环境变量的内存地址，传入环境变量的名
envVar* envAddrGet(char* envName)
{
    //计算hash值
    int envNameHash = envHash(envName);
    //如果未查到，则返回空指针
    int count = 0;
    while (strcmp(envMem[envNameHash].name, envName))
    {
        if (MAX_ENVVAR == count)
        {
            return NULL;
        }
        ++envNameHash;
        ++count;
    }
    //如果查到，返回存储环境变量的内存地址
    return &envMem[envNameHash];
}

//获取环境变量的值，传入变量名，返回指向共享内存中变量值的指针
char* envGet(char* envName)
{
    //获取存储该变量的内存段
    envVar* envAddr = envAddrGet(envName);
    //获取该变量的值
    return envAddr->value;
}

//计算环境变量的hash值，传入变量名，返回hash值
int envHash(char* envName)
{
    //将字符串视为131进制数，转换成十进制数后，对MAX_ENVVAR取模
    int envNameHash = 0;
    while (*envName++)
    {
        envNameHash = envNameHash * 131 + *envName - 'a';
    }
    envNameHash = envNameHash % MAX_ENVVAR;
    return envNameHash;
}

//释放共享内存，用于程序结束时
void envDestroy()
{
    //释放环境变量表
    shmDestroy(envShmID, envMem);
    //释放进程表
    shmDestroy(jobShmID, jobMem);
    //释放mask变量
    shmDestroy(maskShmID, mask);
}

//初始化mask变量
void maskInit()
{
    //创建共享内存，获取共享内存标识符
    //如果共享内存创建失败，标识符返回为-1
    if (-1 == (maskShmID = shmget((key_t)64, sizeof(int), 0666 | IPC_CREAT)))
    {
        errorExit("shmget", SHMGET_FAILED);
    }
    //将共享内存连接到进程的地址空间
    //如果共享内存连接失败，返回地址为-1
    if ((void*)-1 == (mask = shmat(maskShmID, NULL, 0)))
    {
        errorExit("shmat", SHMAT_FAILED);
    }
    //将mask初值设为八进制1000
    *mask = 512;
}

//初始化进程表
void jobInit()
{
    //创建共享内存，获取共享内存标识符
    //如果共享内存创建失败，标识符返回为-1
    if (-1 == (jobShmID = shmget((key_t)817, sizeof(jobMem) * MAX_JOB, 0666 | IPC_CREAT)))
    {
        errorExit("shmget", SHMGET_FAILED);
    }
    //将共享内存连接到进程的地址空间
    //如果共享内存连接失败，返回地址为-1
    if ((void*)-1 == (jobMem = shmat(jobShmID, NULL, 0)))
    {
        errorExit("shamt", SHMAT_FAILED);
    }

    //初始化，将进程表中所有进程的pid设为0
    for (int i = 0; i < MAX_JOB; ++i)
    {
        jobMem[i].pid = 0;
    }

    //初始化第0个进程，保留
    jobMem[0].pid = 0;
    strcpy(jobMem[0].name, SHELLNAME);
    jobMem[0].type = FG;
    jobMem[0].status = RUN;
    jobMem[0].nextJob = NULL;
}

//向进程表中添加进程，返回指向这段内存的指针
job* jobAdd(pid_t pid, char* name, jobType type, jobStatus status)
{
    //计算hash值，优化查询，第0个节点保留
    int i = (pid % MAX_JOB) ? pid % MAX_JOB : 1;
    while (jobMem[i].pid)
    {
        i = (i == MAX_JOB) ? 1 : (i + 1);
    }
    //设置这段内存的结构体的值
    jobMem[i].pid = pid;
    strcpy(jobMem[i].name, name);
    jobMem[i].type = type;
    jobMem[i].status = status;
    //将这段内存设为链表中的第一个节点，先将第1个节点的nextJob指向第0个节点的nextJob
    jobMem[i].nextJob = jobMem[0].nextJob;
    //如果进程表中已经有进程，将新加入的节点的nextJob指向原先的第一个节点
    if (jobMem[i].nextJob)
    {
        jobMem[i].nextJob->lastJob = jobMem + i;
    }
    //第1个节点的lastJob指向第0个节点
    jobMem[i].lastJob = jobMem;
    //第0个节点的nextJob指向新的第1个节点
    jobMem[0].nextJob = jobMem + i;
    //返回指向这段内存的指针
    return (jobMem + i);
}

//获取进程信息的地址，传入参数为pid，返回指向这段内存的指针
job* jobMemAddr(pid_t pid)
{
    //优化查询，计算hash值
    int i = pid % MAX_JOB;
    //如果遍历进程表没有找到，则未查询到，返回空指针
    int count = 0;
    while (jobMem[i].pid != pid)
    {
        if (MAX_JOB == count)
        {
            return NULL;
        }
        i = (i + 1) % MAX_JOB;
        ++count;
    }
    //查询到该pid，返回指向这段内存的指针
    return (jobMem + i);
}

//从进程表中删除进程信息，传入进程的pid
void jobDel(pid_t pid)
{
    //优化查询，计算hash值
    int i = pid % MAX_JOB;
    while (jobMem[i].pid != pid)
    {
        i = (i + 1) % MAX_JOB;
    }
    //将该内存单元中的pid值置0
    jobMem[i].pid = 0;
    //从链表中删除节点
    if (jobMem[i].lastJob)
    {
        jobMem[i].lastJob->nextJob = jobMem[i].nextJob;
    }
    if (jobMem[i].nextJob)
    {
        jobMem[i].nextJob->lastJob = jobMem[i].lastJob;
    }
}

//用于释放共享内存的函数，传入标识符和内存地址
void shmDestroy(int id, void* mem)
{
    //将共享内存从当前进程中分离
    //若分离失败，返回-1
    if (-1 == shmdt(mem))
    {
        errorExit("shmdt", SHMDT_FAILED);
    }
    //删除共享内存段
    //若删除失败，返回-1
    if (-1 == shmctl(id, IPC_RMID, 0))
    {
        errorExit("shmctl", SHMCTL_FAILED);
    }
}