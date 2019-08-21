#!/bin/bash
#UTF-8
#**************************************************************************
#名称：         teacher.sh
#作者：         吴同
#学号：         3170104848
#功能：         教师模块的函数实现
#**************************************************************************

#教师主函数
main_teacher()
{
    echo -n "请输入教师工号："
    read t_id
    #检查学生信息是否存在
    if test 0 = $(cat data/catalog/teacher | grep $t_id | wc -l); then
        echo -e "\033[31m用户不存在！\033[0m"
        #未知异常退出程序
        exit 1;
    fi
    #教师姓名
    login_teacher
    #查找教师姓名
    t_name=$(cat data/catalog/teacher | grep $t_id | awk '{print $2}')
    echo -e "\033[32m欢迎"$t_name"老师！\033[0m"
    #选择操作
    mode_teacher
    #未知异常退出程序
    exit 1
}

#教师登录认证
login_teacher()
{
    #输入不回显
    stty -echo
    #在密码文件中找到该教师的密码
    #教师用户所在的行以字母t开头
    passwd=$(cat data/passwd | grep "^t $t_id" | awk '{print $3}')
    #超过三次输入错误密码，直接退出程序
    for ((i=0; i<3; i++))
    do
        #输入密码
        echo -n "请输入登录密码："
        read passwd_try
        echo ""
        #对密码明文进行sha1运算
        passwd_try_sha=$(echo $passwd_try | shasum | grep -o "^[^[:blank:]]*")
        #字符串比对
        if test $passwd = $passwd_try_sha; then
            #撤销输入不回显
            stty echo
            return 0
        else
            echo -e "\033[31m密码错误！\033[0m"
        fi
    done
    #撤销输入不回显
    stty echo
    #超过三次输入密码错误退出程序
    exit 3
}

#教师主菜单
mode_teacher()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m管理课程信息"
    echo -e "\033[35m2 \033[0m修改用户密码"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  choose_course_t;;
        2)  change_passwd_t;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            mode_teacher;;
    esac
    #未知异常退出程序
    exit 1
}

#选择要操作的课程
choose_course_t()
{
    echo -e "\n请选择课程："
    declare -i i=1
    #第一行为提示输入0返回
    echo -e "\033[35m0 \033[0m返回"
    #列出该教师的所有课程，按课程号排序
    #按课程信息文件夹内的文件名进行匹配，文件名中只保留课程号部分
    for course in $(ls data/teacher_course/$t_id* | grep -o "[[:alnum:]]*$" | sort)
    do
        #按“序号（紫色） 课程号 课程名”的格式输出
        echo -e "\033[35m"$i"\033[0m" $course $(cat data/catalog/course | grep "^$course" | awk '{print $2}')
        i=i+1
    done
    declare -i choose_course
    read choose_course
    #判断输入是否为0（返回）
    if test $choose_course -eq 0; then
        mode_teacher
        #未知异常退出程序
        exit 1
    #判断输入是否合法
    else if test $choose_course -le $(ls data/teacher_course/$t_id* | grep -c "[[:alnum:]]*$"); then
        #将课程列表中的所选项赋值给c_id
        c_id=$(ls data/teacher_course/$t_id* | grep -o "[[:alnum:]]*$" | sort | sed -n $choose_course"p")
        #根据课程号搜索课程名
        c_name=$(cat data/catalog/course | grep "^$c_id" | awk '{print $2}')
        manage_course_t
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m输入非法！\033[0m"
        choose_course_t
        #未知异常退出程序
        exit 1
        fi
    fi
    #未知异常退出程序
        exit 1
}

#教师课程管理菜单
manage_course_t()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m选课名单管理"
    echo -e "\033[35m2 \033[0m课程信息管理"
    echo -e "\033[35m3 \033[0m作业实验管理"
    echo -e "\033[35mr \033[0m返回上级目录"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  manage_student_t;;
        2)  manage_info;;
        3)  manage_work;;
        r)  mode_teacher;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_course_t
            #未知异常退出程序
            exit 1;;
    esac
    #未知异常退出程序
    exit 1
}

#以下为学生管理有关操作的函数

#教师管理学生菜单
manage_student_t()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查看选课学生"
    echo -e "\033[35m2 \033[0m添加选课学生"
    echo -e "\033[35m3 \033[0m删除选课学生"
    echo -e "\033[35m4 \033[0m修改学生信息"
    echo -e "\033[35mr \033[0m返回上级目录"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  query_student_t;;
        2)  add_student_t;;
        3)  delete_student_t;;
        4)  change_student_t;;
        r)  manage_course_t;;
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_student_t;;
    esac
    exit 0
}

#添加选课学生
add_student_t()
{
    echo -e "\n请输入学生学号（输入cancel可取消）："
    read s_id
    #判断输入是否为cancel
    if test "cancel" = $s_id; then
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
    #判断学生信息是否存在
    if test 0 != $(cat data/catalog/student | awk '{print $1}' | grep -c "$s_id"); then
        #判断学生是否选课
        if test -d data/student_course_teacher/$s_id"_"$c_id*; then
            echo -e "\033[31m该学生已选课！\033[0m"
            manage_student_t
            #未知异常退出程序
            exit 1
        fi
        #学生信息存在且未选课，建立选课信息的目录
        mkdir data/student_course_teacher/$s_id"_"$c_id"_"$t_id
        echo -e "\n\033[32m添加成功！\033[0m"
        #函数执行完毕
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
    #学生信息不存在，导入学生信息，再添加选课记录
    echo -e "\n学生信息不存在，请输入学生姓名（输入cancel可取消）："
    read s_name
    if test "cancel" = $s_name; then
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
    #将学生信息写入文件
    echo $s_id $s_name >> data/catalog/student
    #初始密码为123456
    password=123456
    password_md=$(echo $password | md5)
    #将加密过的密码写入密码文件
    echo "s" $s_id $password_md >> data/passwd
    #添加选课记录
    mkdir data/student_course_teacher/$s_id"_"$c_id"_"$t_id
    echo -e "\n\033[32m增加学生成功！\033[0m"
    manage_student_t
    #未知异常退出程序
    exit 1
}

#删除学生选课信息
delete_student_t()
{
    echo -e "\n请输入学生学号（输入cancel可取消）："
    read s_id
    #判断输入是否为cancel
    if test "cancel" = $s_id; then
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
    #判断选课记录的目录是否存在
    if test -d data/student_course_teacher/$s_id"_"$c_id"_"$t_id; then
        #删除选课记录的目录
        rm -rf data/student_course_teacher/$s_id"_"$c_id"_"$t_id
        echo -e "\n\033[32m删除成功！\033[0m"
        manage_student_t
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m无选课信息！\033[0m"
        manage_student_t
        #未知异常退出程序
        exit 1
    fi  
}

#修改学生信息
change_student_t()
{
    echo -e "\n请输入学生学号（输入cancel可取消）："
    read s_id
    #判断输入是否为cancel
    if test "cancel" = $s_id; then
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
    #检查该学生信息是否存在
    if test 0 != $(cat data/catalog/student | awk '{print $1}' | grep -c "$s_id"); then
        echo -e "\n所要修改的学生为：\033[33m"
        #显示该学生的信息，显示为黄色
        cat data/catalog/student | grep "^$s_id"
        echo -e "\n\033[0m请输入修改后的学生姓名（输入cancel可取消）："
        read s_name
        #判断输入是否为cancel
        if test "cancel" = $s_name; then
            manage_student_t
            #未知异常退出程序
            exit 1
        fi
        #删除旧行
        sed -i "" '/'$s_id'/d' data/catalog/student
        #将新信息写入文件
        echo $s_id $s_name >> data/catalog/student
        echo -e "\n\033[32m修改成功！\033[0m"
        manage_student_t
        #未知异常退出程序
        exit 1
    #学生信息不存在     
    else
        echo -e "\033[31m该学号不存在！\033[0m"
        manage_student_t
        #未知异常退出程序
        exit 1
    fi
}

#查询学生信息，选择查询方式
query_student_t()
{
    echo -e "\n请选择查询方式："
    echo -e "\033[35m1 \033[0m按学号查询"
    echo -e "\033[35m2 \033[0m按姓名查询"
    echo -e "\033[35m3 \033[0m查询选课名单"
    #该功能不对教师开放
    #echo -e "\033[35m4 \033[0m查询所有学生"
    echo -e "\033[35mr \033[0m返回上级目录"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  query_student_id;;
        2)  query_student_name;;
        3)  query_student_course;;
        #4)  query_student_all;;
        r)  manage_student_t;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            query_student_t;;
    esac
    #未知异常退出程序
    exit 1
}

#按学号查询学生（核心部分），被调用前s_id变量已被正确设置
query_student()
{
    #检查该学生信息是否存在
    if test 0 = $(cat data/catalog/student | grep -c "^$s_id"); then
        echo -e "\033[31m该学生不存在！\033[0m"
        return 1
    #检查该学生是否选课
    else if test -d data/student_course_teacher/$s_id"_"$c_id"_"$t_id; then
        echo -e "\n所查询的学生为：\033[33m"
        cat data/catalog/student | grep "^$s_id"
        echo -en "\033[0m"
        return 0
    #未选课的学生教师不可查询
    else
        echo -e "\033[31m该学生未选课！\033[0m"
        return 1
        fi
    fi
}

#按学号查询学生
query_student_id()
{
    echo -e "\n请输入学生学号：（输入cancel可取消）"
    read s_id
    #判断输入是否为cancel
    if test "cancel" = $s_id; then
        query_student_t
        #未知异常退出程序
        exit 1
    fi
    #调用查询函数
    query_student
    query_student_t
    #未知异常退出程序
    exit 1
}

#按姓名查找学生
query_student_name()
{
    echo -e "\n请输入学生姓名：（输入cancel可取消）"
    read s_name
    #判断输入是否为cancel
    if test "cancel" = $s_name; then
        query_student_t
        #未知异常退出程序
        exit 1
    fi
    #查找姓名对应的学号，若有重名按学号排序
    for s_id in $(cat data/catalog/student | grep "$s_name$" | sort | awk '{print $1}')
    do
        #调用查询函数
        query_student
    done
    query_student_t
    #未知异常退出程序
    exit 1
}

#查看课程的所有选课学生
query_student_course()
{
    #判断是否有学生选课
    if test 0 != $(ls -1d data/student_course_teacher/*"_"$c_id"_"$t_id | wc -l); then
        echo -e "\n所查询的学生为：\033[33m"
        #通过选课信息的文件名查找学号
        for s_id in $(ls -1d data/student_course_teacher/*"_"$c_id"_"$t_id | cut -d "/" -f 3 | grep -o "^[[:digit:]]*")
        do
            cat data/catalog/student | grep "^$s_id"
        done
        echo -en "\033[0m"
        query_student_t
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m无学生选课！\033[0m"
        query_student_t
        #未知异常退出程序
        exit 1
    fi
}

#查看所有学生
query_student_all()
{
    #判断学生信息是否为空
    if test 0 != $(cat data/catalog/student | wc -l); then
        echo -e "\n所查询的学生为：\033[33m"
        #输出按学号排序
        cat data/catalog/student | sort
        echo -en "\033[0m"
        query_student_t
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m学生不存在！\033[0m"
        query_student_t
        #未知异常退出程序
        exit 1
    fi
}

#以下为管理课程信息的函数
#管理课程信息的菜单
manage_info()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m发布信息"
    echo -e "\033[35m2 \033[0m编辑信息"
    echo -e "\033[35m3 \033[0m删除信息"
    echo -e "\033[35m4 \033[0m显示信息"
    echo -e "\033[35mr \033[0m返回上级目录"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  add_info;;
        2)  edit_info;;
        3)  delete_info;;
        4)  list_info
            manage_info;;
        r)  manage_course_t;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_info
            #未知异常退出程序
            exit 1;;
    esac
    #未知异常退出程序
    exit 1
}

#添加课程信息
add_info()
{
    echo -e "请输入课程信息："
    read line
    #向文件写入新信息
    #每条信息用'|'分割
    echo -n "$line|" >> data/teacher_course/$t_id"_"$c_id
    echo -e "\n\033[32m信息发布成功！\033[0m"
    manage_info
    #未知异常退出程序
    exit 1
}

#删除课程信息
delete_info()
{
    #列出所有课程信息
    list_info
    echo -e "\n请选择要删除的信息："
    declare -i choice
    read choice
    #判断输入的选项序号是否合法
    #每条信息之间用'|'分割，获取总信息条数
    if test $choice -le $(awk -v RS='\0' -F '|' '{print NF-1}' data/teacher_course/$t_id"_"$c_id); then
        #将该条信息以外的所有信息重新写入文件，覆盖原文件
        #awk内两个for循环先后执行，分别复制该条信息之前的和之后的
        echo $(awk -v RS='\0' -v col_del=$choice -v ORS="" -F '|' '{for(i=1; i<col_del; i++){print $i"|"} for(i=col_del+1; i<NF; i++){print $i"|"}}' data/teacher_course/$t_id"_"$c_id) > data/teacher_course/$t_id"_"$c_id
    else
        echo -e "\033[31m非法输入！\033[0m"
    fi
    manage_info
    #未知异常退出程序
    exit 1
}

#编辑课程信息
edit_info()
{
    #显示所有信息
    list_info
    echo -e "\n请选择要编辑的信息："
    declare -i choice
    read choice
    #判断输入的选项序号是否合法
    #每条信息之间用'|'分割，获取总信息条数
    if test $choice -le $(awk -v RS='\0' -F '|' '{print NF-1}' data/teacher_course/$t_id"_"$c_id); then
        echo "请输入修改后的信息："
        read newLine
        #覆盖原文件，该条信息前后的原文复制
        #awk内两个for循环，先复制该条信息之前的，再写入新信息，再复制该条信息之后的
        echo $(awk -v RS='\0' -v col_edit=$choice -v ORS="" -v line=$newLine -F '|' '{for(i=1; i<col_edit; i++){print $i"|"} {print line"|"} for(i=col_edit+1; i<NF; i++){print $i"|"}}' data/teacher_course/$t_id"_"$c_id) > data/teacher_course/$t_id"_"$c_id
    else
        echo -e "\033[31m非法输入！\033[0m"
    fi
    manage_info
    #未知异常退出程序
    exit 1
}

#列出所有信息
list_info()
{
    echo -e "\n所有课程信息如下：\033[32m"
    #以'|'为分割符，逐条信息列出
    for ((i=1; i<=$(awk -v RS='\0' -F '|' '{print NF-1}' data/teacher_course/$t_id"_"$c_id); i++))
    do
        echo -e $i $(cat data/teacher_course/$t_id"_"$c_id | cut -d "|" -f $i)
    done
    echo -en "\033[0m"
    return 0
}

#以下为管理课程任务的函数
#管理任务信息的菜单
manage_work()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m布置任务"
    echo -e "\033[35m2 \033[0m编辑任务"
    echo -e "\033[35m3 \033[0m删除任务"
    echo -e "\033[35m4 \033[0m显示任务"
    echo -e "\033[35m5 \033[0m完成情况"
    echo -e "\033[35mr \033[0m返回上级目录"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  add_work;;
        2)  edit_work;;
        3)  delete_work;;
        4)  list_work
            manage_work;;
        5)  check_work;;
        r)  manage_course_t;;
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_work
            #未知异常退出程序
            exit 1;;
    esac
    #未知异常退出程序
    exit 1
}

#添加新任务
add_work()
{
    echo -e "\n请输入任务名称（输入cancel可取消）："
    read work_name
    #判断输入是否为cancel
    if test "cancel" = $work_name; then
        manage_work
        #未知异常退出程序
        exit 1
    fi
    #在所有该课程的学生选课目录下创建任务目录，用于存放学生提交的文件
    for s_dir in $(ls -d data/student_course_teacher/*$c_id"_"$t_id)
    do
        mkdir $s_dir/$work_name
    done
    echo -e "\n\033[32m任务创建成功！\033[0m"
    manage_work
    #未知异常退出程序
    exit 1
}

#删除任务
delete_work()
{
    #列出所有任务
    list_work
    echo -e "\n请选择要删除的任务："
    declare -i choice
    read choice
    #判断输入是否合法
    if test $choice -le $(ls $s_dir | wc -l); then
        #根据输入的序号确定任务名称
        work_del=$(ls $s_dir | head -n $choice)
        #删除所有该课程的学生选课目录下的该作业目录
        rm -rf data/student_course_teacher/*$c_id"_"$t_id/$work_del
    else
        echo -e "\033[31m非法输入！\033[0m"
    fi
    manage_work
    #未知异常退出程序
    exit 1
}

#编辑任务名称
edit_work()
{
    #列出所有任务
    list_work
    echo -e "\n请选择要编辑的任务："
    declare -i choice
    read choice
    #判断输入是否合法
    if test $choice -le $(ls $s_dir | wc -l); then
        #根据输入的序号确定任务名称
        work_old=$(ls $s_dir | head -n $choice)
        echo -e "\n请输入新的任务名称："
        read work_new
        for s_dir in $(ls -d data/student_course_teacher/*$c_id"_"$t_id/$work_old)
        do
            #重命名所有该课程的学生选课目录下的该作业目录
            mv $s_dir $(echo $s_dir | sed 's/'$work_old'/'$work_new'/')
        done
    else
        echo -e "\033[31m非法输入！\033[0m"
    fi
    manage_work
    #未知异常退出程序
    exit 1
}

#列出所有任务
list_work()
{
    #任选一个选课学生的选课目录
    s_dir=$(ls -d data/student_course_teacher/*$c_id"_"$t_id | head -1)
    echo -e "\n所布置的任务为：\033[32m"
    declare -i i=1
    #列出选课目录下的所有目录名，按字典序排列
    for work in $(ls $s_dir | sort)
    do
        echo $i $work
        i=i+1
    done
    echo -en "\033[0m"
    return 0
}

#检查任务提交情况
check_work()
{
    #列出所有任务
    list_work
    echo -e "\n请选择要检查的任务："
    declare -i choice
    read choice
    #判断输入是否合法
    if test $choice -le $(ls $s_dir | wc -l); then
        #根据输入的序号确定任务名称
        work_check=$(ls $s_dir | head -n $choice)
        echo -e "\n完成情况如下："
        #检查每个选课学生的该作业目录
        for s_dir in data/student_course_teacher/*$c_id"_"$t_id/$work_check
        do
            #从作业目录的路径名中提取学号
            s_id=$(echo $s_dir | cut -d '/' -f 3 | cut -d '_' -f 1)
            #若作业目录下有文件，视为已提交，否则视为未提交
            if test 0 != $(ls $s_dir | wc -l); then
                echo -e $s_id "\033[32m已提交\033[0m"
            else
                echo -e $s_id "\033[34m未提交\033[0m"
            fi
        done
        echo -en "\033[0m"
    else
        echo -e "\033[31m非法输入！\033[0m"
    fi
    manage_work
    #未知异常退出程序
    exit 1
}

#修改教师密码
change_passwd_t()
{
    #身份验证
    login_teacher
    #输入不回显
    stty -echo
    echo -n "请输入新密码："
    read passwd
    echo ""
    echo -n "请再输入一遍："
    read passwd_again
    echo ""
    #检验两次输入是否一致
    if test $passwd != $passwd_again; then
        echo -e "\033[31m两次输入不一致！\033[0m"
        mode_admin
        #未知异常退出程序
        exit 1
    fi
    #对密码明文进行加密
    passwd_sha=$(echo $passwd | shasum | grep -o "^[^[:blank:]]*")
    #删除密码文件中的旧行
    sed -i "" '/'$t_id'/d' data/passwd
    #向密码文件中写入新行
    echo "t" $t_id $passwd_sha >> data/passwd
    #撤销输入不回显
    stty echo
    #修改成功提示，显示为绿色
    echo -e "\n\033[32m修改成功！\033[0m"
    mode_teacher
    #未知异常退出程序
    exit 1
}
