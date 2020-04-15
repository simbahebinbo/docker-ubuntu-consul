#!/bin/bash

#启动consul程序

#consul可执行文件
CONSUL_BIN=$1
#工作目录
WORK_DIR=$2
#consul的目录
CONSUL_DIR=$3
#应用程序名
APP_NAME=$4
#节点名
NODE_NAME=consul-client-${APP_NAME}
#进程文件
NODE_PIDFILE=${WORK_DIR}/consul.pid
#网卡名
ADDR=eth0
#本地IP
LOCAL_IP=127.0.0.1

#获取容器IP
NODE_IP=$(ip -f inet address | grep inet | /bin/grep eth0 | awk '{print $2}' | awk -F\/ '{print $1}')

# 只允许当前ip注册，即只允许该容器内的应用程序注册到该consul节点
# 以 client 模式启动
# 加入到 server 模式 的节点组成的集群
nohup ${CONSUL_BIN} agent \
-pid-file=${NODE_PIDFILE} \
-bootstrap-expect=0 \
-advertise=${NODE_IP} -bind=${NODE_IP} -client=${LOCAL_IP} \
-protocol=3 \
-node=${NODE_NAME} \
-rejoin -retry-interval=30s \
-data-dir=${CONSUL_DIR}/data \
-log-file=${CONSUL_DIR}/log/${NODE_NAME}.log -log-level=INFO \
-retry-join=172.18.18.141 -retry-join=172.18.18.142 -retry-join=172.18.18.143 -retry-join=172.18.18.144 -retry-join=172.18.18.145 -retry-join=172.18.18.146 \
-join=172.18.18.141 -join=172.18.18.142 -join=172.18.18.143 -join=172.18.18.144 -join=172.18.18.145 -join=172.18.18.146 \
> /dev/null 2>&1


