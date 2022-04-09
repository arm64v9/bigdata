#!/bin/bash

wkdir=`pwd`

# 添加 Ip、hostname 到 /etc/hosts 文件里面
addIpToHostFile() {
    ip=$1
    hostname=$2

    # 查询 $ip 是否存在于 /etc/hosts 里面
    egrep "^$ip" /etc/hosts >& /dev/null
    if [ $? -eq 0 ]; then
        sed -i "/^$ip/d" /etc/hosts
    fi
 
    # 把 ip、hostname 添加到 /etc/hosts 中
    echo "$ip $hostname" >> /etc/hosts
}

# 执行 ssh 免密登录之前，hosts 文件里面需要存储每台机器的 ip 地址
editHostFile() {
 
    # host_ip.txt 文件中读取 ip 和 hostname
    while read line
    do
        # 提取文件中的 ip
        ip=`echo $line | cut -d " " -f1`

        # 提取文件中的用户名
        hostname=`echo $line | cut -d " " -f2`

        addIpToHostFile $ip $hostname
    done < $wkdir/iphosts.conf
}

editHostFile
