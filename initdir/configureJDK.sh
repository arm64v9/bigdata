#! /bin/bash

wkdir=`pwd`

configureJDK() {
    # 在 frames.txt 中查看是否需要安装 java
    javaInfo=`egrep "^jdk" $wkdir/frames.conf`
 
    java=`echo $javaInfo | cut -d " " -f1`
    isInstall=`echo $javaInfo | cut -d " " -f2`

    # 是否安装
    if [[ $isInstall = "true" ]];then
 
        # 查看 /opt/frames 目录下是否有 java 安装包
        javaIsExists=`find /opt/frames -name $java`
    
        if [[ ${#javaIsExists} -ne 0 ]]; then
        
            if [ -d /usr/lib/java ];then
                rm -rf /usr/lib/java
            fi
 
            mkdir /usr/lib/java && chmod -R 777 /usr/lib/java
   
            # 解压到指定文件夹 /usr/lib/java 中 
            echo "开启解压jdk安装包"
            tar -zxvf $javaIsExists -C /usr/lib/java >& /dev/null
            echo "jdk安装包解压完毕"
    
            java_home=`find /usr/lib/java -maxdepth 1 -name "jdk*"`

            # 在 /etc/profile 配置 JAVA_HOME
            profile=/etc/profile
            sed -i "/^export JAVA_HOME/d" $profile
            echo "export JAVA_HOME=$java_home" >> $profile
 
            # 在 /etc/profile 配置 PATH
            sed -i "/^export PATH=\$PATH:\$JAVA_HOME\/bin/d" $profile
            echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> $profile
            sed -i "/^export CLASSPATH=.:\$JAVA_HOME/d" $profile
            echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> $profile

            # 更新 /etc/profile 文件
            source /etc/profile && source /etc/profile
        else
            echo "/opt/frames目录下没有jdk安装包"
        fi
    else
        echo "这个节点不需要安装"
    fi
}

configureJDK
