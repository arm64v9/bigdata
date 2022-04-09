#! /bin/bash

wkdir=`pwd`

sshFreeLogin() {
    # 检测 expect 服务是否存在，不存在则使用 yum 安装 expect
    if ! rpm -q expect; then
        yum install expect -y
    fi

    # 密钥对不存在则创建密钥
    [ ! -f /root/.ssh/id_rsa.pub ] && ssh-keygen -t rsa -P "" -f /root/.ssh/id_rsa


    while read line;do
        # 提取文件中的 hostname
        hostname=`echo $line | cut -d " " -f2`

        # 提取文件中的用户名
        user_name=`echo $line | cut -d " " -f3`

        # 提取文件中的密码
        pass_word=`echo $line | cut -d " " -f4`

        set timeout -1
        expect << EOF
            # 复制公钥到目标主机
            spawn ssh-copy-id $hostname
            expect {
                "yes/no" { send "yes\n";exp_continue } 
                "password" { send "$pass_word\n";exp_continue }
                eof
            }
EOF
        # 读取存储 ip 的文件 
    done < $wkdir/iphosts.conf
 
}

sshFreeLogin
