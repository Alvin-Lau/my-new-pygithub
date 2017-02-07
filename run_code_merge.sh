#!/usr/bin/bash

set -x
# chkconfig: - 85 15
# description: run_code_merge is for code review merge

export repo_list="zstackorg/zstack-utility zstackorg/zstack zstackorg/zstack-vyos zxwing/zstack-store zxwing/premium zxwing/mevoco-ui zstackorg/zstack-woodpecker"
#export repo_list="LeiLiu1991/test_auto LeiLiu1991/test_auto_2"
# Alvin-Lau token
export GITHUB_API_TOKEN="f4d99a92cf913468bc168173cb6c9ac78c85c2e2"

# leiliu toke
#export GITHUB_API_TOKEN="87ded860feb6f432a5d2567e181858b7cf118fb9"

#slack token
export SLACK_USER_TOKEN="xoxp-16588718595-94852999572-120140093584-cd8141b5e434d253204c23f05f240eef"

pip install pygithub 
pip install slackclient

if [ "$1" == "get_issues" ];then
    python ${JENKINS_HOME}/code_review_script/get_issues.py 
fi

if [ "$1" == "add_labels" ];then
    python ${JENKINS_HOME}/code_review_script/add_labels.py
fi

#ps -ef | grep python | grep deal_pull_request
#if [ $? -ne 0 ];then
#   python ${JENKINS_HOME}/code_review_script/deal_pull_request.py &
#   #python /home/jenkins/code_review_script/deal_pull_request.py &
#fi

#ps -ef | grep python | grep merge_pull_reques
#if [ $? -ne 0 ];then
#    python /home/my-new-pygithub/merge_pull_request.py &
#fi
