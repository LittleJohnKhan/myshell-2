#!/bin/bash
#UTF-8
#**************************************************************************
#名称：         student.sh
#作者：         吴同
#学号：         3170104848
#功能：         学生模块的函数实现
#**************************************************************************

#学生主函数
main_student()
{
    echo -n "请输入学生学号："
    read s_id
    #检查学生信息是否存在
    if test 0 = $(cat data/catalog/student | grep $s_id | wc -l); then
        echo -e "\033[31m用户不存在！\033[0m"
        #未知异常退出程序
        exit 1;
    fi
    #学生登录
    login_student
    #查找学生姓名
    t_name=$(cat data/catalog/student | grep $s_id | awk '{print $2}')
    echo -e "\033[32m欢迎"$t_name"同学！\033[0m"
    #选择操作
    mode_student
    #未知异常退出程序
    exit 1
}

#学生登录认证
login_student()
{
    #输入不回显
    stty -echo
    #在密码文件中找到该学生的密码
    #学生用户所在的行以字母s开头
    passwd=$(cat data/passwd | grep "^s $s_id" | awk '{print $3}')
    #超过三次输入错误密码，直接退出程序
    for ((i=0; i<3; i++))
    do
        #输入密码
        echo -n "请输入登录密码："
        read passwd_try
        echo ""
        #对密码明文进行md5运算
        passwd_try_md5=$(echo $passwd_try | md5)
        #字符串比对
        if test $passwd = $passwd_try_md5; then
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

#学生主菜单
mode_student()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查看课程信息"
    echo -e "\033[35m2 \033[0m修改用户密码"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  choose_course_s;;
        2)  change_passwd_s;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            mode_student;;
    esac
    #未知异常退出程序
    exit 1
}

#选择要操作的课程
choose_course_s()
{
    echo -e "\n请选择课程："
    declare -i i=1
    #第一行为提示输入0返回
    echo -e "\033[35m0 \033[0m返回"
    #列出该学生的所有课程，按课程号排序
    #按选课信息文件夹内的文件名进行匹配
    #第一次分割去掉上级目录名，第二次分割取课程号
    for course in $(ls -d data/student_course_teacher/$s_id* | cut -d "/" -f 3 | cut -d "_" -f 2 | sort)
    do
        #按“序号（紫色） 课程号 课程名”的格式输出
        echo -e "\033[35m"$i"\033[0m" $course $(cat data/catalog/course | grep "^$course" | awk '{print $2}')
        i=i+1
    done
    declare -i choose_course
    read choose_course
    #判断输入是否为0（返回）
    if test $choose_course -eq 0; then
        mode_student
        #未知异常退出程序
        exit 1
    #判断输入是否合法
    else if test $choose_course -le $(ls -d data/student_course_teacher/$s_id* | wc -l); then
        #将课程列表中的所选项赋值给c_id
        c_id=$(ls -d data/student_course_teacher/$s_id* | cut -d "/" -f 3 | cut -d "_" -f 2 | sort | sed -n $choose_course"p")
        #搜索该学生的该课程对应的文件名，确定教师
        t_id=$(ls -d data/student_course_teacher/$s_id*$c_id* | cut -d "/" -f 3 | cut -d "_" -f 3)
        #根据课程号搜索课程名
        c_name=$(cat data/catalog/course | grep "^$c_id" | awk '{print $2}')
        manage_course_s
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m输入非法！\033[0m"
        choose_course_s
        #未知异常退出程序
        exit 1
        fi
    fi
    #未知异常退出程序
    exit 1
}

#学生课程管理菜单
manage_course_s()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查看通知"
    echo -e "\033[35m2 \033[0m管理作业"
    echo -e "\033[35mr \033[0m返回上级"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  show_info;;
        2)  manage_work_s;;
        r)  mode_student;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_course_s;;
    esac
    #未知异常退出程序
    exit 1
}

#显示课程信息
show_info()
{
    echo -e "\n所有课程信息如下：\033[32m"
    #读取课程信息文件，课程信息以'|'分割，利用awk得出信息总条数
    for ((i=1; i<=$(awk -v RS='\0' -F '|' '{print NF-1}' data/teacher_course/$t_id"_"$c_id); i++))
    do
        #显示第i条信息，信息显示为绿色
        echo -e $i $(cat data/teacher_course/$t_id"_"$c_id | cut -d "|" -f $i)
    done
    echo -en "\033[0m"
    manage_course_s
    #未知异常退出程序
    exit 1
}

#以下为学生作业有关操作的函数
#学生作业操作的菜单
manage_work_s()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查看作业"
    echo -e "\033[35m2 \033[0m提交作业"
    echo -e "\033[35m3 \033[0m重交作业"
    echo -e "\033[35m4 \033[0m检查作业"
    echo -e "\033[35mr \033[0m返回上级"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  show_work
            manage_work_s;;
        2)  add_work;;
        3)  edit_work;;
        4)  check_work;;
        r)  mode_student;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_work_s;;
    esac
    #未知异常退出程序
    exit 1
}

#显示该课程的所有任务的提交情况
show_work()
{
    #任务文件所在的目录
    s_dir=$(ls -d data/student_course_teacher/*$c_id"_"$t_id | head -1)
    #显示该课程的所有任务
    echo -e "\n该课程的任务为：\033[32m"
    declare -i i=1
    #按任务名称的字母序排列
    for work in $(ls $s_dir | sort)
    do
        #显示任务名称
        echo -en $i $work" "
        #如果该目录下存在文件，则视为已提交，反之视为未提交
        if test 0 = $(ls data/student_course_teacher/$s_id"_"$c_id"_"$t_id/$work | wc -l); then
            echo "未提交"
        else
            echo "已提交"
        fi
        i=i+1
    done
    echo -en "\033[0m"
    #函数执行完毕后返回
    return 0
}

#学生提交作业
add_work()
{
    #显示所有任务完成情况
    show_work
    echo -e "\n请选择要提交的任务（输入0返回）："
    declare -i work_choose
    read work_choose
    #判断输入是否为0（返回）
    if test $work_choose -eq 0; then
        manage_work_s
        #未知异常退出程序
        exit 1
    #判断输入是否合法
    else if test $work_choose -le $(ls $s_dir | wc -l); then
        #任务序号对应的任务名
        work_name=$(ls $s_dir | sort | sed -n $work_choose"p")
        echo -e "\n请输入要提交的文件（输入cancel可取消）："
        read fileName
        #判断输入是否为cancel
        if test "cancel" = $fileName; then
            manage_course_s
            #未知异常退出程序
            exit 1
        fi
        #将选定的文件复制到任务目录下
        cp $fileName $s_dir/$work_name
        echo -e "\n\033[32m提交成功！\033[0m"
        #未知异常退出程序
        manage_course_s
        exit 1
    else
        echo -e "\033[31m输入非法！\033[0m"
        choose_course_s
        #未知异常退出程序
        exit 1
        fi
    fi
}

#学生编辑已提交作业
edit_work()
{
    #显示所有任务完成情况
    show_work
    echo -e "\n请选择要重交的任务（输入0返回）："
    declare -i work_choose
    read work_choose
    #判断输入是否为0（返回）
    if test $work_choose -eq 0; then
        manage_work_s
        #未知异常退出程序
        exit 1
    #判断输入是否合法
    else if test $work_choose -le $(ls $s_dir | wc -l); then
        #任务序号对应的任务名
        work_name=$(ls $s_dir | sort | sed -n $work_choose"p")
        echo -e "\n请输入要提交的文件（输入cancel可取消）："
        read fileName
        #判断输入是否为cancel
        if test "cancel" = $fileName; then
            manage_course_s
            #未知异常退出程序
            exit 1
        fi
        #删除该任务已提交的文件
        rm $s_dir/$work_name/*
        #将选定的文件复制到任务目录下
        cp $fileName $s_dir/$work_name
        echo -e "\n\033[32m重交成功！\033[0m"
        manage_course_s
         #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m输入非法！\033[0m"
        choose_course_s
        #未知异常退出程序
        exit 1
        fi
    fi
}

#查看已提交作业
check_work()
{
    #显示所有任务完成情况
    show_work
    echo -e "\n请选择要检查的任务（输入0返回）："
    declare -i work_choose
    read work_choose
    if test $work_choose -eq 0; then
        manage_work_s
        #未知异常退出程序
        exit 1
    #判断输入是否合法
    else if test $work_choose -le $(ls $s_dir | wc -l); then
        #任务序号对应的任务名
        work_name=$(ls $s_dir | sort | sed -n $work_choose"p")
        echo -e "\n请输入下载地址（输入cancel可取消）："
        read downloadDir
        #判断输入是否为cancel
        if test "cancel" = $downloadDir; then
            manage_course_s
            #未知异常退出程序
            exit 1
        fi
        #将作业目录复制到所输入的目录下
        cp -r $s_dir/$work_name $downloadDir
        echo -e "\n\033[32m下载成功！\033[0m"
        manage_course_s
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m输入非法！\033[0m"
        choose_course_s
        #未知异常退出程序
        exit 1
        fi
    fi
}

#修改学生密码
change_passwd_s()
{
    #身份验证
    login_student
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
    passwd_md5=$(echo $passwd | md5)
    #删除密码文件中的旧行
    sed -i "" '/'$s_id'/d' data/passwd
    #向密码文件中写入新行
    echo "s" $s_id $passwd_md5 >> data/passwd
    #撤销输入不回显
    stty echo
    #修改成功提示，显示为绿色
    echo -e "\n\033[32m修改成功！\033[0m"
    mode_student
    #未知异常退出程序
    exit 1
}
