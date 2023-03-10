FROM ubuntu:16.04

USER root

#静默安装
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NOWARNINGS yes

#更新
RUN apt-get update && apt-get install --assume-yes apt-utils

#安装程序依赖的包
RUN apt-get install -yq --no-install-recommends build-essential
RUN apt-get install -yq --no-install-recommends pkg-config


#权限
RUN apt-get install -yq --no-install-recommends sudo

#加密
RUN apt-get install -yq --no-install-recommends openssl
RUN apt-get install -yq --no-install-recommends libssl-dev
RUN apt-get install -yq --no-install-recommends ca-certificates

#编辑器
RUN apt-get install -yq --no-install-recommends vim

#网络
RUN apt-get install -yq --no-install-recommends iputils-ping
RUN apt-get install -yq --no-install-recommends net-tools
RUN apt-get install -yq --no-install-recommends iproute2

#中文支持
RUN apt-get install -yq --no-install-recommends locales

#升级
RUN apt-get -y upgrade

#支持中文
RUN echo "zh_CN.UTF-8 UTF-8" > /etc/locale.gen && locale-gen zh_CN.UTF-8 en_US.UTF-8


# Configure environment
ENV SHELL=/bin/bash
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
ENV USER_HOME=/home/$NB_USER



# Create jovyan user with UID=1000 and in the 'users' group
#用户名 jovyan  密码:123456
RUN useradd -p `openssl passwd 123456` -m -s $SHELL -u $NB_UID -G sudo $NB_USER
#sudo时免密
RUN echo "jovyan  ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

#解析主机名
RUN echo "127.0.1.1 $(hostname)" >> /etc/hosts

USER $NB_USER

#接收传递过来的参数
ARG CONSUL_NODES


ENV WORK_DIR=$USER_HOME/work
ENV CONSUL_DIR=$WORK_DIR/consul
ENV CONSUL_BIN=/usr/local/bin/consul
ENV TINI_BIN=/usr/local/bin/tini
ENV APP_NAME=example
ENV RUN_SHELL=run.sh
ENV CONSUL_SERVERS=${CONSUL_NODES}

# Setup jovyan home directory
RUN mkdir $WORK_DIR && mkdir $USER_HOME/.local

#刷新库文件
RUN sudo ldconfig

#进入到工作目录
WORKDIR $WORK_DIR

# Add Tini
ADD tini $TINI_BIN
RUN sudo chmod +x $TINI_BIN && sudo chgrp $NB_USER $TINI_BIN && sudo chown $NB_USER $TINI_BIN

#添加consul可执行文件
ADD consul $CONSUL_BIN
RUN sudo chmod +x $CONSUL_BIN && sudo chgrp $NB_USER $CONSUL_BIN && sudo chown $NB_USER $CONSUL_BIN

#创建consul的各种目录
RUN mkdir -p $CONSUL_DIR 
RUN sudo chmod +w $CONSUL_DIR && sudo chgrp $NB_USER $CONSUL_DIR && sudo chown $NB_USER $CONSUL_DIR
RUN mkdir -p $CONSUL_DIR/data 
RUN sudo chmod +w $CONSUL_DIR/data && sudo chgrp $NB_USER $CONSUL_DIR/data && sudo chown $NB_USER $CONSUL_DIR/data
RUN mkdir -p $CONSUL_DIR/config 
RUN sudo chmod +w $CONSUL_DIR/config && sudo chgrp $NB_USER $CONSUL_DIR/config && sudo chown $NB_USER $CONSUL_DIR/config
RUN mkdir -p $CONSUL_DIR/log 
RUN sudo chmod +w $CONSUL_DIR/log && sudo chgrp $NB_USER $CONSUL_DIR/log && sudo chown $NB_USER $CONSUL_DIR/log
RUN mkdir -p $CONSUL_DIR/scripts 
RUN sudo chmod +w $CONSUL_DIR/scripts && sudo chgrp $NB_USER $CONSUL_DIR/scripts && sudo chown $NB_USER $CONSUL_DIR/scripts
RUN mkdir -p $CONSUL_DIR/web 
RUN sudo chmod +w $CONSUL_DIR/web && sudo chgrp $NB_USER $CONSUL_DIR/web && sudo chown $NB_USER $CONSUL_DIR/web

#添加启动consul的脚本
ADD ${RUN_SHELL} $WORK_DIR/${RUN_SHELL}
RUN sudo chmod +x $WORK_DIR/${RUN_SHELL} && sudo chgrp $NB_USER $WORK_DIR/${RUN_SHELL} && sudo chown $NB_USER $WORK_DIR/${RUN_SHELL}

#添加保持运行状态的脚本，用于调试
ADD idle.sh $WORK_DIR/idle.sh
RUN sudo chmod +x $WORK_DIR/idle.sh && sudo chgrp $NB_USER $WORK_DIR/idle.sh && sudo chown $NB_USER $WORK_DIR/idle.sh

#暴露端口
EXPOSE 8300/tcp 8301/tcp 8301/udp 8302/tcp 8302/udp 8500/tcp 8500/udp 8600/tcp 8600/udp

#暴露卷
VOLUME $CONSUL_DIR

#启动consul
ENTRYPOINT exec $WORK_DIR/${RUN_SHELL} ${CONSUL_DIR} ${APP_NAME} ${CONSUL_SERVERS}

#保持运行状态，用于调试
# ENTRYPOINT exec $TINI_BIN -- $WORK_DIR/idle.sh





