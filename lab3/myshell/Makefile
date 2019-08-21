all: mysh

#编译器
CC = gcc
#编译器选项
OPTIONS = -Wall -O3

#用户级的软件安装路径
INSTDIR = /usr/local/bin

#编译过程
mysh: main.c main.h parse.o builtin.o environment.o
	$(CC) $(OPTIONS) -o mysh main.c parse.o builtin.o environment.o

environment.o: environment.c environment.h main.h
	$(CC) $(OPTIONS) -c environment.c

parse.o: parse.c parse.h main.h builtin.h environment.h
	$(CC) $(OPTIONS) -c parse.c

builtin.o: builtin.c builtin.h main.h
	$(CC) $(OPTIONS) -c builtin.c

#清除编译产生的文件
clean:
	-rm -f {*.o,mysh}

#安装mysh
#先将mysh复制到INSTDIR指定的路径中，再赋予执行权限，取消其他用户的写权限
install: mysh
	@   if [ -d $(INSTDIR) ]; then \
            cp mysh $(INSTDIR); \
			cp readme $(INSTDIR)/readme_mysh; \
            chmod a+x $(INSTDIR)/mysh; \
            chmod og-w $(INSTDIR)/mysh; \
			chmod og-w $(INSTDIR)/readme_mysh; \
        fi

#卸载mysh
uninstall: mysh
	-rm -f $(INSTDIR)/mysh
	-rm -f $(INSTDIR)/readme_mysh
