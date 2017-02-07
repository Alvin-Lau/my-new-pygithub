#!/usr/bin/bash

# chkconfig: - 85 15
# description: run_code_merge is for code review merge

#export repo_list="zstackorg/zstack-utility zstackorg/zstack zstackorg/zstack-vyos zxwing/zstack-store zxwing/premium zxwing/mevoco-ui zstackorg/zstack-woodpecker"
export repo_list="LeiLiu1991/test_auto LeiLiu1991/test_auto_2"
# Alvin-Lau token
#export GITHUB_API_TOKEN="f4d99a92cf913468bc168173cb6c9ac78c85c2e2"

# leiliu toke
export GITHUB_API_TOKEN="87ded860feb6f432a5d2567e181858b7cf118fb9"

#slack token
export SLACK_USER_TOKEN="xoxp-16588718595-94852999572-120140093584-cd8141b5e434d253204c23f05f240eef"

#pip install pygithub 
#pip install slackclient
apt-get install jq

#python ${JENKINS_HOME}/code_review_script/merge_pull_request.py

echo $repo_list
DB_USER="root"
DB_IP="172.20.198.222"
DB_PASSWD="password"
DB_NAME="auto_code_review"
sql="select code_review_id, base_commit_sha, url, ref_repo, milestone, epic from pull_request where test_state=\"NEW\" ORDER BY code_review_id DESC LIMIT 1"
ret=$(mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e "$sql");  
base_commit_sha=`echo $ret| awk -F " " '{print $8}'`
url=`echo $ret| awk -F " " '{print $9}'`
ref_repo=`echo $ret| awk -F " " '{print $10}'`
milestone=`echo $ret| awk -F " " '{print $11}'`
epic=`echo $ret| awk -F " " '{print $12}'`
a=`curl https://api.github.com/repos/LeiLiu1991/test_auto_2/pulls?state="open"` | jq ' length'

for i in `cat a | jq 'length'`
#for result in $ret
#do
#   echo $result
#done
