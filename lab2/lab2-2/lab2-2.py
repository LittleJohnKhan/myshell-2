#**************************************************************************
#名称：         lab2-2.py
#作者：         吴同
#学号：         3170104848
#功能：         随机生成100个10000以内的整数，并随机换行，以测试lab2-2.sh的正确性。
#               生成数据写入lab2-2.in文件中。
#参数：         无
#**************************************************************************

import random
#随机生成10000个整数
hundred=100
array = []
for i in range(hundred):
    array.append(random.randint(0, 10000))
#生成结果写入lab2-2.in文件中
with open('lab2-2.in', 'w') as f:
    for element in array:
        f.write(str(element))
        #写入一个数据后，随机选择空格或换行
        if random.randint(0, 1) is 1:
            f.write(' ')
        else:
            f.write('\n')
