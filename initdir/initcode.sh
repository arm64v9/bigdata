#! /bin/bash

initnode() {
    wkdir=`pwd`

    # 拷贝安装包到 /opt/frames 下
    echo "拷贝安装包到 /opt/frames 下"
    cp -r $wkdir/frames /opt/

    # host 配置文件修改
    echo "将集群 ip 及其映射的 hostname 添加到 /etc/hosts 中"
    bash $wkdir/initdir/addClusterIps.sh

    # 配置 SSH 无密码登录
    echo "集群各节点之间配置 SSH 无密码登录"
    bash $wkdir/initdir/sshFreeLogin.sh

    # 配置 JDK 环境
    echo "配置jdk环境"
    bash $wkdir/initdir/configureJDK.sh


    echo "--------------------"
    echo "|   环境初始化成功！|"
    echo "--------------------"
}

copy() {
    while read line
    do
        # 提取文件中的用户名
        nodename=`echo $line | cut -d " " -f2`

        # 把文件都拷贝到其它节点 
        if [ $nodename != `hostname` ]; then
            scp -r ../bigdata root@$nodename:/opt
        fi
    done < $wkdir/iphosts.conf


}

rsvtool() {
    # 安装必要工具
    for tool in expect unzip; do
        if ! rpm -q $tool; then
            yum install $tool -y
        fi
    done
}

rsvtool
initnode 
if [ ! -f .ignore_copy ]; then
    touch .ignore_copy
    copy
fi
