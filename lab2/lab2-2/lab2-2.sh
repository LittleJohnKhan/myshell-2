#!/bin/bash
#UTF-8
#**************************************************************************
#名称：         lab2-2.sh
#作者：         吴同
#学号：         3170104848
#功能：         1. 统计100个整数的平均值、最大值、最小值。
#               2. 将100个整数按从小到大的顺序输出。
#参数：         无
#**************************************************************************

#检查运行程序时传入的参数个数是否符合要求，该程序不传入参数。
#错误信息显示为红色。
if test $# -gt 0; then
    echo -e "\033[31m格式错误！\033[0m"
    exit 1
fi

#从键盘输入100个整数
#将100用变量表示，方便数据规模的修改
hundred=100
echo "输入"$hundred"个整数："
declare -i sum=0
declare -i i=0
#支持以多行输入，读满100个整数为止
#外层循环每次读入一行
while test $i -lt $hundred
do
    #将读入的文本行划分为数组
    read -a line
    #内层循环每次处理行中的一个数
    for integer in ${line[@]}
    do
        if test $i -lt $hundred; then
            array[i++]=$integer
            sum+=$integer
        fi
    done
done

#输出结果，排序结果显示为黄色
#先讲数组以列输出到管道，再用sort命令排序
sorted=$(echo ${array[@]} | tr ' ' '\n' | sort -g)
echo -e "排序后的数组为：\033[33m"
echo $sorted

#平均值、最小值、最大值显示为紫色
echo -en "\033[0m平均值为：\033[35m"
#平均值直接计算
echo `expr $sum / $hundred`
echo -en "\033[0m最小值为：\033[35m"
#最小值和最大值直接提取排序结果的第一个和最后一个
echo $sorted | grep -o "^[[:digit:]]*[^[:blank:]]"
echo -en "\033[0m最大值为：\033[35m"
echo $sorted | grep -o "[^[:blank:]][[:digit:]]*$"
echo -en "\033[0m"

#退出程序
exit 0