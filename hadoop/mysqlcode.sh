#!/bin/bash

wkdir=`pwd`

# 导入AzkabanSQL
function importAzkabanSQL()
{
    sql=$1
    sqlInfoIsExists=`find /opt/frames -name $sql`
    if [[ ${#sqlInfoIsExists} -ne 0 ]];then
        #删除旧的
        azkaban_sql_home_old=`find /tmp -maxdepth 1 -name "*azkaban-sql*"`
        for i in $azkaban_sql_home_old;do
                rm -rf $i
        done
        # 创建安装目录
        mkdir /tmp/azkaban-sql
        # 解压Azkaban-SQL
        tar -zxvf $sqlInfoIsExists -C /tmp/azkaban-sql >& /dev/null
        echo "azkaban-sql压缩包解压完毕"
        sqlPath=`find /tmp/azkaban-sql/ -maxdepth 2 -name "*create-all-sql*"`
        # 导入SQL
        mysql  -uroot -e "drop database if exists azkaban;"
        mysql  -uroot -e "create database azkaban;"
        mysql  -uroot -e "use azkaban;source $sqlPath;"
    fi
    echo "Azkaban SQL导入成功"
}

function installMysql()
{
    # 在frames.txt中查看是否需要安装mysql
    mysqlInfo=`egrep "^mysql-rpm-pack" $wkdir/frames.conf`

    mysql=`echo $mysqlInfo | cut -d " " -f1`
    isInstall=`echo $mysqlInfo | cut -d " " -f2`
    installNode=`echo $mysqlInfo | cut -d " " -f3` 
    currentNode=`hostname`

    #是否安装
    if [[ $isInstall = "true" && $currentNode = $installNode ]];then

    # 查看/opt/frames目录下是否有hadoop安装包
    mysqlIsExists=`find /opt/frames -name $mysql`
    echo $mysqlIsExists
     if [[ ${#mysqlIsExists} -ne 0  ]];then

        # 安装依赖
        yum install -y net-tools libaio perl numactl
        yum remove mariadb-libs -y

        # 安装数据库
        rpm -ivh $mysqlIsExists/mysql-community-*

        # 字符集配置
        # echo "default-character-set=utf8" >> /etc/my.cnf
        sed -i '/character-set-server=utf8/d' /etc/my.cnf
        echo "character-set-server=utf8" >> /etc/my.cnf

        # 启动Mysql
        systemctl start mysqld.service

        # 配置开机自启动
        systemctl enable mysqld

        # 查找密码
        # grep 'temporary password' /var/log/mysqld.log
        export MYSQL_PWD=`egrep "A temporary password" /var/log/mysqld.log | awk '{print $NF}'`

        # 执行Mysql修改密码
        # select user,host,password, from mysql.user
        mysqlRootPasswd=`egrep "^mysql-root-password" $wkdir/database.conf | cut -d " " -f2`
        mysql --connect-expired-password -uroot -e "set password for root@localhost=password('$mysqlRootPasswd');"
        export MYSQL_PWD=$mysqlRootPasswd

        # 为root用户开通远程权限
        mysql --connect-expired-password -uroot -e "grant all privileges on *.* to 'root'@'%' identified by '$mysqlRootPasswd' with grant option;"
        mysql --connect-expired-password -uroot -e "flush privileges;"

        # 删除匿名用户
        mysql -uroot -e "delete from mysql.user where user='';"
        mysql  -uroot -e "flush privileges;"

        # 添加新用户
        mysqlHivePasswd=`egrep "^mysql-hive-password" $wkdir/database.conf | cut -d " " -f2`
        mysql  -uroot -e "create user 'hive'@'%' identified by '$mysqlHivePasswd';"
        mysql  -uroot -e "flush privileges;"

        # 创建新数据库
        mysql  -uroot -e "create database hive default character set utf8 collate utf8_general_ci;"

        # 为新用户赋权
        mysql  -uroot -e "grant all privileges on hive.* to 'hive'@'%' identified by '$mysqlHivePasswd';"
        mysql  -uroot -e "flush privileges;"
        
        # 导入Azkaban SQL导入
        sqlInfo=`egrep "azkaban-sql" $wkdir/frames.conf`
        sql=`echo $sqlInfo | cut -d " " -f1`
        isSqlInstall=`echo $sqlInfo | cut -d " " -f2`
        # 判断是否需要导入Azkaban SQL
        if [[ $isSqlInstall = "true" ]];then
            importAzkabanSQL $sql
        fi
        echo "--------------------"
        echo "|  Mysqk安装成功！  |"
        echo "--------------------"
       
     fi
    else
     echo "mysql不允许安装在 `hostname` 节点"
    fi
    
}

installMysql
