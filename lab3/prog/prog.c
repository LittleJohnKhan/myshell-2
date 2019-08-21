/**************************************************************************
 * 名称：           prog.c
 * 作者：           吴同
 * 学号：           3170104848
 * 功能：           1、父进程创建子进程p1和p2，p1创建子进程p3
 *                  2、每个进程打印自己的信息，包括名称，pid，ppid
 *                  3、p1和p2之间实现通信，p3调用ls -l
**************************************************************************/

//系统调用
#include <unistd.h>
#include <sys/types.h>
#include <sys/shm.h>
//库函数
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KEY 1926    //共享内存的键值
#define MAXTEXT 64  //字符串通信的最大长度

//共享内存中的结构单元，用于进程间的通信
typedef struct sharedMemoryStruct
{
    int flag;           //用于记录写入这条消息的进程号
    char text[MAXTEXT]; //用于记录消息的内容
} sharedMemoryStruct;

//显示进程信息的函数，进程名为传入的字符串，pid和ppid显示为绿色
//样例：
//传入参数："main"
//输出结果：I am	main	process. My PID is 94563. My PPID is 78712.
void procDisplay(const char* procName)
{
    printf("I am\t%s\tprocess. My PID is \033[32m%d\033[0m. My PPID is \033[32m%d\033[0m.\n", procName, getpid(), getppid());
}

//用于处理fork失败的函数，将错误信息以红色字体输出到stderr，并结束程序
void forkError()
{
    fprintf(stderr, "\033[31mfork failed\n\033[0m");
    exit(1);
}

//初始化共享内存的函数，传入的参数为共享内存的键值和存储内存地址的指针，用在程序开始时
//由于要对内存进行分配，不可传入内存地址的值，而是要传入二级指针
int sharedMemoryInitialize(key_t key, sharedMemoryStruct** shaeredMemoryAddr)
{
    //创建共享内存，获取共享内存标识符
    //内存大小为一个结构单元的大小
    int shmid = shmget(key, sizeof(sharedMemoryStruct), 0666 | IPC_CREAT);
    //如果共享内存创建失败，标识符返回为-1
    if (-1 == shmid)
    {
        fprintf(stderr, "\033[31mshmget failed\n\033[0m");
        exit(2);
    }
    //将共享内存连接到进程的地址空间
    *shaeredMemoryAddr = (sharedMemoryStruct*)shmat(shmid, NULL, 0);
    //如果共享内存连接失败，返回地址为-1
    if ((void*)-1 == *shaeredMemoryAddr)
    {
        fprintf(stderr, "\033[31mshmat failed\n\033[0m");
        exit(3);
    }
    //设置共享内存中flag数据的值为0，表示没有数据待读取
    (*shaeredMemoryAddr)->flag = 0;
    //返回共享内存的标识符
    return shmid;
}

//向共享内存中写入数据的函数，传入的参数为共享内存的地址和待写入的数据
void sharedMemoryWrite(sharedMemoryStruct* shaeredMemory, const char* textWrite)
{
    //如果内存处于占用状态，暂不写入
    while (shaeredMemory->flag)
    {
        usleep(200);
    }
    //开始写入，将flag设为写数据的进程号
    shaeredMemory->flag = getpid();
    //将待写入的数据写入共享内存
    strncpy(shaeredMemory->text, textWrite, MAXTEXT);
}

//读取共享内存中数据的函数，传入参数为内存地址
void sharedMemoryRead(sharedMemoryStruct* shaeredMemory)
{
    //判断共享内存中是否有可读的数据，如果没有数据或数据为本进程自己写入的，则不可读，等待
    while (getpid() == shaeredMemory->flag || !shaeredMemory->flag)
    {
        usleep(200);
    }
    //读出数据，显示到屏幕上，提示信息为黄色
    printf("\033[33m%d read:\033[0m %s\n", getpid(), shaeredMemory->text);
    //将flag置0，表示没有数据
    shaeredMemory->flag = 0;
}

//销毁共享内存的函数，传入的参数为共享内存的标识符和内存地址，用在程序结束时
void shaeredMemoryDestroy(int shmid, sharedMemoryStruct* shaeredMemory)
{
    //将共享内存从当前进程中分离
    //若分离失败，返回-1
    if (-1 == shmdt((void*)shaeredMemory))
    {
        fprintf(stderr, "\033[31mshmdt failed\n\033[0m");
        exit(4);
    }
    //删除共享内存段
    //若删除失败，返回-1
    if (-1 == shmctl(shmid, IPC_RMID, 0))
    {
        fprintf(stderr, "\033[31mshmctl failed\n\033[0m");
        exit(5);
    }
}

//主函数
int main()
{
    //初始化共享内存
    sharedMemoryStruct* shaeredMemory = NULL;
    int shmid = sharedMemoryInitialize(KEY, &shaeredMemory);

    //创建子进程p1
    pid_t pid;
    pid = fork();
    switch (pid)
    {
        //fork失败
        case -1:
            forkError();
        //子进程p1
        case 0:
            //p1创建子进程p3
            pid = fork();
            switch (pid)
            {
                //fork失败
                case -1:
                    forkError();
                //子进程p3
                case 0:
                    //显示p3进程信息
                    procDisplay("p3");
                    //执行ls -l
                    printf("\033[33mp3 exec:\033[3m ls -l\033[0m\n");
                    execlp("ls", "ls", "-l", NULL);
                    break;
                //子进程p1
                default:
                    //显示p1进程信息
                    procDisplay("p1");
                    //等待子进程p3结束
                    wait(NULL);
                    //从共享内存中读出数据
                    sharedMemoryRead(shaeredMemory);
                    //向共享内存中写入数据
                    sharedMemoryWrite(shaeredMemory, "Child process p1 is sending a message!");
            }
            break;
        //主进程
        default:
            //主进程创建子进程p2
            pid = fork();
            switch (pid)
            {
                //fork失败
                case -1:
                    forkError();
                //子进程p2
                case 0:
                    //显示p2进程信息
                    procDisplay("p2");
                    //向共享内存中写入数据
                    sharedMemoryWrite(shaeredMemory, "Child process p2 is sending a message!");
                    //从共享内存中读出数据
                    sharedMemoryRead(shaeredMemory);
                    break;
                //主进程
                default:
                    //显示主进程信息
                    procDisplay("main");
                    //等待子进程结束
                    waitpid(pid, NULL, 0);
                    //释放分配的共享内存
                    shaeredMemoryDestroy(shmid, shaeredMemory);
            }
    }
    //程序结束
    exit(0);
}
