#!/bin/bash
#UTF-8
#**************************************************************************
#名称：         admin.sh
#作者：         吴同
#学号：         3170104848
#功能：         管理员模块的函数实现
#**************************************************************************

#管理员主函数
main_admin()
{
    #管理员登录
    login_admin
    echo -e "\033[32m欢迎admin！\033[0m"
    #选择管理员操作
    mode_admin
    #未知异常退出程序
    exit 1
}

#管理员登录认证
login_admin()
{
    #输入不回显
    stty -echo
    #加密运算所用的变量
    salt="admin"
    salt_reverse="nimda"
    #在密码文件中找到管理员密码
    #管理员密码所在行第一个字段为"a"
    passwd=$(cat data/passwd | grep ^a | awk '{print $3}')
    #超过三次输入错误密码，直接退出程序
    for ((i=0; i<3; i++))
    do
        #输入密码
        echo -n "请输入管理员登录密码："
        read passwd_try
        echo ""
        #加密运算
        #先将明文进行md5加密，再在尾部加上"admin"字符，再进行一次md5，
        #再在尾部加上"nimda"，再进行一次sha1加密
        passwd_try_md5=$(echo $(echo "$passwd_try" | md5)$salt | md5)
        passwd_try_sha=$(echo $(echo "$passwd_try_md5")$salt_reverse | shasum | grep -o "^[^[:blank:]]*")
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

#以下是与管理功能有关的函数

#管理员主菜单
mode_admin()
{
    #序号显示为紫色
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m管理教师信息"
    echo -e "\033[35m2 \033[0m管理课程信息"
    echo -e "\033[35m3 \033[0m修改用户密码"
    echo -e "\033[35mq \033[0m退出系统"
    #输入所选择模式的序号
    read mode
    case $mode in
        1)  manage_teacher;;
        2)  manage_course;;
        3)  change_password;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            mode_admin;;
    esac
    #未知异常退出程序
    exit 1
}

#教师信息管理主菜单
manage_teacher()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查询教师信息"
    echo -e "\033[35m2 \033[0m增加教师信息"
    echo -e "\033[35m3 \033[0m删除教师信息"
    echo -e "\033[35m4 \033[0m修改教师信息"
    echo -e "\033[35m5 \033[0m绑定课程信息"
    echo -e "\033[35m6 \033[0m取消课程绑定"
    echo -e "\033[35mr \033[0m返回上级菜单"
    echo -e "\033[35mq \033[0m退出系统"
    #输入所选择模式的序号
    read mode
    case $mode in
        1)  query_teacher;;
        2)  add_teacher;;
        3)  delete_teacher;;
        4)  change_teacher;;
        5)  bind_course;;
        6)  cancel_bind_course;;
        r)  mode_admin;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_teacher;;
    esac
    #未知异常退出程序
    exit 1
}

#课程信息管理主菜单
manage_course()
{
    echo -e "\n请选择操作："
    echo -e "\033[35m1 \033[0m查询课程信息"
    echo -e "\033[35m2 \033[0m增加课程信息"
    echo -e "\033[35m3 \033[0m删除课程信息"
    echo -e "\033[35m4 \033[0m修改课程信息"
    echo -e "\033[35mr \033[0m返回上级菜单"
    echo -e "\033[35mq \033[0m退出系统"
    #输入所选择模式的序号
    read mode
    case $mode in
        1)  query_course;;
        2)  add_course;;
        3)  delete_course;;
        4)  change_course;;
        r)  mode_admin;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            manage_course;;
    esac
    #未知异常退出程序
    exit 1
}

#以下是与教师信息管理有关的函数

#增加教师用户
add_teacher()
{
    #输入教师工号
    echo -e "\n请输入教师工号（输入cancel可取消）："
    read t_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $t_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #判断该工号是否已存在
    if test 0 != $(cat data/catalog/teacher | awk '{print $1}' | grep -c "$t_id"); then
        echo -e "\033[31m该工号已存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #若该工号不存在，则添加教师
    #输入教师姓名
    echo -e "\n请输入教师姓名（输入cancel可取消）："
    read t_name
    #判断输入的字符串是否为cancel
    if test "cancel" = $t_name; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #将新添加的教师信息写入教师信息文件中
    echo $t_id $t_name >> data/catalog/teacher
    #将教师账号添加进密码文件中，初始密码为123456
    password=123456
    #将明文进行sha1加密后写入文件
    password_sha=$(echo $password | shasum | grep -o "^[^[:blank:]]*")
    echo "t" $t_id $password_sha >> data/passwd
    #提示操作成功，显示为绿色
    echo -e "\n\033[32m增加教师成功！\033[0m"
    manage_teacher
    #未知异常退出程序
    exit 1
}

#删除教师用户
delete_teacher()
{
    #输入教师工号
    echo -e "\n请输入教师工号（输入cancel可取消）："
    read t_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $t_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查该用户是否存在
    if test 0 != $(cat data/catalog/teacher | awk '{print $1}' | grep -c "$t_id"); then
        #显示该教师的工号和姓名，显示为黄色
        echo -e "\n所要删除的教师为：\033[33m"
        cat data/catalog/teacher | grep "^$t_id"
        echo -en "\033[31m确认删除吗？\033[0m"
        #确认删除
        read verify
        case $verify in
            y | Y | yes | Yes | YES)
                #将教师信息文件和密码文件中对应的行删掉
                sed -i "" '/'$t_id'/d' data/catalog/teacher
                sed -i "" '/'$t_id'/d' data/passwd
                echo -e "\n\033[32m删除成功！\033[0m";;
            *)
                echo "取消删除";;
        esac
        manage_teacher
        #未知异常退出程序
        exit 1 
    else
        #错误信息显示为红色
        echo -e "\033[31m该工号不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
}

#修改教师信息
change_teacher()
{
    #输入教师工号
    echo -e "\n请输入教师工号（输入cancel可取消）："
    read t_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $t_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查该用户是否存在
    if test 0 != $(cat data/catalog/teacher | awk '{print $1}' | grep -c "$t_id"); then
        #显示该教师的工号和姓名，显示为黄色
        echo -e "\n所要修改的教师为：\033[33m"
        cat data/catalog/teacher | grep "^$t_id"
        #输入修改的信息
        echo -e "\n\033[0m请输入修改后的教师姓名（输入cancel可取消）："
        read t_name
        if test "cancel" = $t_name; then
            manage_teacher
            #未知异常退出程序
            exit 1
        fi
        #删除文件中的旧行
        sed -i "" '/'$t_id'/d' data/catalog/teacher
        #向文件中写入新行
        echo $t_id $t_name >> data/catalog/teacher
        #修改成功提示信息显示为绿色
        echo -e "\n\033[32m修改成功！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1    
    else
        echo -e "\033[31m该工号不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
}

#查询教师信息，选择查询模式
query_teacher()
{
    echo -e "\n请选择查询方式："
    echo -e "\033[35m1 \033[0m按教师工号查询"
    echo -e "\033[35m2 \033[0m按教师姓名查询"
    echo -e "\033[35m3 \033[0m显示所有教师"
    echo -e "\033[35mr \033[0m返回上级菜单"
    echo -e "\033[35mq \033[0m退出系统"
    #输入所选择模式的序号
    read mode
    case $mode in
        1)  query_teacher_id;;
        2)  query_teacher_name;;
        3)  query_teacher_all;;
        r)  manage_teacher;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            query_teacher;;
    esac
    #未知异常退出程序
    exit 1
}

#以下是与教师信息查询有关的函数

#按工号查询教师信息
query_teacher_id()
{
    #输入教师工号
    echo -e "\n请输入教师工号："
    read t_id
    if test 0 != $(cat data/catalog/teacher | grep -c "^$t_id"); then
        #显示查询到的教师信息，信息显示为黄色
        echo -e "\n所查询的教师为：\033[33m"
        cat data/catalog/teacher | grep "^$t_id"
        echo -en "\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m教师不存在！\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    fi
}

#按姓名查询教师信息
query_teacher_name()
{
    #输入教师工号
    echo -e "\n请输入教师姓名："
    read t_name
    if test 0 != $(cat data/catalog/teacher | grep -c "$t_name$"); then
        #显示查询到的教师信息，信息显示为黄色
        echo -e "\n所查询的教师为：\033[33m"
        #如果出现同名教师，输出结果按工号排序
        cat data/catalog/teacher | grep "$t_name$" | sort
        echo -en "\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m教师不存在！\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    fi
}

#输出所有教师信息
query_teacher_all()
{
    #检查教师文件中是否有记录存在
    if test 0 != $(cat data/catalog/teacher | wc -l); then
        echo -e "\n所查询的教师为：\033[33m"
        #输出结果按工号排序，显示为黄色
        cat data/catalog/teacher | sort
        echo -en "\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m教师不存在！\033[0m"
        query_teacher
        #未知异常退出程序
        exit 1
    fi
}

#以下是与教师课程绑定有关的函数

#绑定课程
bind_course()
{
    echo -e "\n请输入教师工号（输入cancel可取消）："
    read t_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $t_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查教师账户是否存在
    if test 0 = $(cat data/catalog/teacher | grep -c "^$t_id"); then
        echo -e "\033[31m教师不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    echo -e "\n请输入课程代号（输入cancel可取消）："
    read c_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查课程信息是否存在
    if test 0 = $(cat data/catalog/course | grep -c "^$c_id"); then
        echo -e "\033[31m课程不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查教师与课程是否已经绑定
    if test -f "data/teacher_course/$t_id""_$c_id"; then
        echo -e "\033[31m该教师已绑定该课程！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #所有检查均通过，绑定教师与课程，创建"教师工号_课程号"文件
    touch "data/teacher_course/$t_id""_$c_id"
    echo -e "\n\033[32m教师与课程成功绑定！\033[0m"
    manage_teacher
    #未知异常退出程序
    exit 1
}

#取消绑定
cancel_bind_course()
{
    #判断输入的字符串是否为cancel
    echo -e "\n请输入教师工号（输入cancel可取消）："
    read t_id
    if test "cancel" = $t_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查教师账户是否存在
    if test 0 = $(cat data/catalog/teacher | grep -c "^$t_id"); then
        echo -e "\033[31m教师不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    echo -e "\n请输入课程代号（输入cancel可取消）："
    read c_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_id; then
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查课程信息是否存在
    if test 0 = $(cat data/catalog/course | grep -c "^$c_id"); then
        echo -e "\033[31m课程不存在！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
    #检查教师与课程是否已经绑定
    #若已经绑定，删除"教师工号_课程号"文件
    if test -f "data/teacher_course/$t_id""_$c_id"; then
        rm "data/teacher_course/$t_id""_$c_id"
        echo -e "\n\033[32m教师与课程解除绑定！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m该教师未与该课程绑定！\033[0m"
        manage_teacher
        #未知异常退出程序
        exit 1
    fi
}

#以下是与课程管理有关的函数

#增加新的课程信息
add_course()
{
    echo -e "\n请输入课程代号（输入cancel可取消）："
    read c_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_id; then
        manage_course
        #未知异常退出程序
        exit 1
    fi
    #检查课程信息是否已经存在
    if test 0 != $(cat data/catalog/course | awk '{print $1}' | grep -c "$c_id"); then
        echo -e "\033[31m课程代号已存在！\033[0m"
        manage_course
        #未知异常退出程序
        exit 1
    fi
    echo -e "\n请输入课程名称（输入cancel可取消）："
    read c_name
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_name; then
        manage_course
        #未知异常退出程序
        exit 1
    fi
    #将增加的课程写入课程信息文件
    echo $c_id $c_name >> data/catalog/course
    echo -e "\n\033[32m增加课程成功！\033[0m"
    manage_course
    #未知异常退出程序
    exit 1
}

#删除课程信息
delete_course()
{
    echo -e "\n请输入课程代号（输入cancel可取消）："
    read c_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_id; then
        manage_course
        #未知异常退出程序
        exit 1
    fi
    #检查课程信息是否存在
    if test 0 != $(cat data/catalog/course | awk '{print $1}' | grep -c "$c_id"); then
        echo -e "\n所要删除的课程为：\033[33m"
        #显示课程信息，显示为黄色
        cat data/catalog/course | grep "^$c_id"
        #确认是否删除
        echo -en "\033[31m确认删除吗？\033[0m"
        read verify
        case $verify in
            y | Y | yes | Yes | YES)
                #删除课程信息文件中对应的行
                sed -i "" '/'$c_id'/d' data/catalog/course
                echo -e "\n\033[32m课程删除成功！\033[0m";;
            *)
                echo "取消删除";;
        esac
        manage_course
        #未知异常退出程序
        exit 1
        
    else
        echo -e "\033[31m该课程不存在！\033[0m"
        manage_course
        #未知异常退出程序
        exit 1
    fi
}

#修改课程信息
change_course()
{
    echo -e "\n请输入课程代号（输入cancel可取消）："
    read c_id
    #判断输入的字符串是否为cancel
    if test "cancel" = $c_id; then
        manage_course
        #未知异常退出程序
        exit 1
    fi
    #检查课程信息是否存在
    if test 0 != $(cat data/catalog/course | awk '{print $1}' | grep -c "$c_id"); then
        echo -e "\n所要修改的课程为：\033[33m"
        #显示课程信息，显示为黄色
        cat data/catalog/course | grep "^$c_id"
        #读入新的课程名称
        echo -e "\n\033[0m请输入新的课程名称（输入cancel可取消）："
        read c_name
        #判断输入的字符串是否为cancel
        if test "cancel" = $c_name; then
            manage_course
            #未知异常退出程序
            exit 1
        fi
        #删除文件中的旧行
        sed -i "" '/'$c_id'/d' data/catalog/course
        #向文件中写入新行
        echo $c_id $c_name >> data/catalog/course
        echo -e "\n\033[32m修改课程成功！\033[0m"
        manage_course
        #未知异常退出程序
        exit 1 
    else
        echo -e "\033[31m该课程不存在！\033[0m"
        manage_course
        #未知异常退出程序
        exit 1
    fi
}

#查询课程信息，选择查询方式
query_course()
{
    echo -e "\n请选择查询方式："
    echo -e "\033[35m1 \033[0m按课程代号查询"
    echo -e "\033[35m2 \033[0m按课程名称查询"
    echo -e "\033[35m3 \033[0m显示所有课程"
    echo -e "\033[35mr \033[0m返回上级菜单"
    echo -e "\033[35mq \033[0m退出系统"
    read mode
    case $mode in
        1)  query_course_id;;
        2)  query_course_name;;
        3)  query_course_all;;
        r)  manage_course;;
        #正常退出程序
        q)  exit 0;;
        *)  echo -e "\033[31m输入非法！\033[0m"
            query_course;;
    esac
    #未知异常退出程序
    exit 1
}

#以下是与课程信息查询有关的函数

#按课程号查询课程
query_course_id()
{
    echo -e "\n请输入课程代号："
    read c_id
    #判断该课程号是否存在
    if test 0 != $(cat data/catalog/course | grep -c "^$c_id"); then
        echo -e "\n所查询的课程为：\033[33m"
        #显示课程信息，显示为黄色
        cat data/catalog/course | grep "^$c_id"
        echo -en "\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m课程不存在！\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    fi
}

#按课程名查询课程信息
query_course_name()
{
    echo -e "\n请输入课程名称："
    read c_name
    #判断该课程名称是否存在
    if test 0 != $(cat data/catalog/course | grep -c "$c_name$"); then
        echo -e "\n所查询的课程为：\033[33m"
        #显示课程信息，显示为黄色
        #若存在多个同名课程，按课程号排序
        #支持正则表达式
        cat data/catalog/course | grep "$c_name$" | sort
        echo -en "\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m课程不存在！\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    fi
}

#显示所有课程信息
query_course_all()
{
    #判断是否有课程信息存在
    if test 0 != $(cat data/catalog/course | wc -l); then
        echo -e "\n所查询的课程为：\033[33m"
        #显示所有课程信息，按课程号排序
        cat data/catalog/course | sort
        echo -en "\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m课程不存在！\033[0m"
        query_course
        #未知异常退出程序
        exit 1
    fi
}

#以下是与修改密码有关的函数

#修改密码，判断所修改用户的类型并调用相关函数
change_password()
{
    #管理员身份验证
    login_admin
    #输入要修改密码的用户名
    echo -e "\n请输入用户名（输入cancel可取消）："
    read user
    #判断输入的字符串是否为cancel
    if test "cancel" = $user; then
        mode_admin
        return 1
    fi
    #判断用户是否存在
    if test 0 != $(cat data/passwd | awk '{print $2}' | grep -c "$user"); then
        #判断用户类型
        case $(cat data/passwd | grep -o "^[^[:blank:]][[:blank:]]$user" | awk '{print $1}') in
            a)  change_passwd_admin;;
            t)  change_passwd_teacher $user;;
            s)  change_passwd_student $user;;
        esac
        mode_admin
        #未知异常退出程序
        exit 1
    else
        echo -e "\033[31m该用户不存在！\033[0m"
        mode_admin
        #未知异常退出程序
        exit 1
    fi 
}

#修改管理员密码
change_passwd_admin()
{
    #输入不回显
    stty -echo
    #进行加密用的变量
    salt="admin"
    salt_reverse="nimda"
    #输入两次新密码
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
        exit 1
    fi
    #将明文转换为密文
    passwd_md5=$(echo $(echo "$passwd" | md5)$salt | md5)
    passwd_sha=$(echo $(echo "$passwd_md5")$salt_reverse | shasum | grep -o "^[^[:blank:]]*")
    #删除密码文件中的旧行
    sed -i "" '/admin/d' data/passwd
    #将新行写入密码文件
    echo "a" "admin" $passwd_sha >> data/passwd
    #撤销输入不回显
    stty echo
    #输出修改成功的提示，字体为绿色
    echo -e "\n\033[32m修改成功！\033[0m"
    mode_admin
    #未知异常退出程序
    exit 1
}

#修改教师密码
change_passwd_teacher()
{
    #输入不回显
    stty -echo
    #输入两次新密码
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
        exit 1
    fi
    #将明文转换为密文，进行一次sha1加密
    passwd_sha=$(echo $passwd | shasum | grep -o "^[^[:blank:]]*")
    #删除密码文件中的旧行
    sed -i "" '/'$1'/d' data/passwd
    #将新行写入密码文件
    echo "t" $1 $passwd_sha >> data/passwd
    #撤销输入不回显
    stty echo
    #输出修改成功的提示，字体为绿色
    echo -e "\n\033[32m修改成功！\033[0m"
    mode_admin
    #未知异常退出程序
    exit 1
}

#修改学生密码
change_passwd_student()
{
    #输入不回显
    stty -echo
    #输入两次新密码
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
        exit 1
    fi
    #将明文转换为密文，进行一次md5加密
    passwd_md5=$(echo $passwd | md5)
    #删除密码文件中的旧行
    sed -i "" '/'$1'/d' data/passwd
    #将新行写入密码文件
    echo "t" $1 $passwd_md5 >> data/passwd
    #撤销输入不回显
    stty echo
    #输出修改成功的提示，字体为绿色
    echo -e "\n\033[32m修改成功！\033[0m"
    mode_admin
    #未知异常退出程序
    exit 1
}
