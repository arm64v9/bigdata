#!/bin/bash

wkdir=`pwd`

main() {
    # 本节点初始化
    bash $wkdir/hadoop/hadoopcode.sh

    nodearray=`awk -F" " '{print $2}' $wkdir/iphosts.conf`

    # 其它所有节点初始化
    for node in $nodearray; do
        if [ $node != `hostname` ]; then
            ssh $node "cd /opt/bigdata && bash ./hadoop/hadoopcode.sh"
        fi
    done

}

main

