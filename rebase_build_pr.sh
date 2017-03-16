#!/usr/bin/bash

#for line in `mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e "select * from pull_request where test_state=\"NEW\";"`
#do
#    echo $line
#done
#COMMAND1="mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review"
#while read -a row
#do
#    ref_repo=${row[0]}
#    ref_branch=${row[4]#*:}
#    user=${row[5]}
#    echo $ref_repo
#    echo $ref_branch
#    echo ${row[4]}
#    #echo $user
#    #echo "${row[0]}..${row[1]}..${row[2]}"
#    echo "aaaaaaaaaaaaaaaaaaaa"
#done< <(echo "select ref_repo, epic, user from pull_request where test_state=\"NEW\" limit 1;" | ${COMMAND1})
set -x
#sudo dpkg --configure -a
#sudo apt-get install -y mysql

which mysql
BUILD_TYPE="PR_rebase_build"
ZSTACK="master"
ZSTACK_AGENT="master"
ZSTACK_UTILITY="master"
ZSTACK_DASHBOARD="master"
MEVOCO_UI="master"
PREMIUM="master"
ZSTACK_STORE="master"
ZSTACK_VYOS="master"
ZSTACK_DISTRO="master"
START_TIME=${SECONDS}


first_pull_request=$(ssh 172.20.198.222 'mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e "select url, base, epic, code_review_id from pull_request where test_state=\"NEW\" limit 1;" |awk "NR>1"');
if [ "$first_pull_request" = "" ];then
    echo "No new PR need to be built"
    exit 0
fi
pr_build=$(ssh 172.20.198.222 'mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e "create table if not exists pull_request_build(pr_build_id INT NOT NULL AUTO_INCREMENT, url VARCHAR(170) NOT NULL, build_state CHAR(30) NOT NULL, log VARCHAR(170) NOT NULL, PRIMARY KEY(pr_build_id))"');
url=`echo $first_pull_request | awk -F  " "  '{print $1}'`
epic=`echo $first_pull_request | awk -F " " '{print $3}'`
epic_num=`echo $epic | awk -F "@@" '{print $2}'`
code_review_id=`echo $first_pull_request | awk -F " " '{print $4}'`
if [ $? -ne 0 ];then
    echo "Fail to update mysql test_state as BUILDING"
    exit 3
fi

all_pull_request="Test"
echo $all_pull_request
if [[ "$epic_num" == "" ]];then
    all_pull_request=${first_pull_request}
    ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILDING: ${BUILD_NUMBER}'  where code_review_id=$code_review_id;\""
    num_pull_request=2

else
    #ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILDING: ${BUILD_NUMBER}'  where epic='${epic}' and test_state not regexp 'closed|merged.*';\""
    all_code_review_id=$(ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"select max(code_review_id) from pull_request where epic='${epic}' group by url\"");
    code_review_id=`echo ${all_code_review_id} | sed 's/max(code_review_id) //' | sed 's/ /\,/g'`
    #code_review_id="(${code_review_id})"
    ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILDING: ${BUILD_NUMBER}' where code_review_id in (${code_review_id})\""
    sleep 1
    all_pull_request=$(ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"select url, base, epic, code_review_id from pull_request where epic='${epic}' and test_state regexp 'BUILDING.*';\" |awk \"NR>1\"");

fi
num_pull_request=`echo $all_pull_request | awk -F "${epic}"  '{print NF}'`
if [ $epic_num -gt $num_pull_request ];then
    echo "There should be more PR"
    ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='NEW'  where epic='${epic}' and test_state='BUILDING: ${BUILD_NUMBER}';\""
    exit 127
fi
user=`echo $first_pull_request | awk -F " " '{print $2}'`
base_branch=${user#*:}

ZSTACK=$base_branch
ZSTACK_AGENT="master"
ZSTACK_UTILITY=$base_branch
ZSTACK_DASHBOARD="master"
MEVOCO_UI=$base_branch
PREMIUM=$base_branch
ZSTACK_STORE=$base_branch
ZSTACK_VYOS=$base_branch
ZSTACK_DISTRO=$base_branch

all_url=""
cd ${WORKSPACE}/
for ((i=1; i < $num_pull_request; i++))
do
    url=`echo $all_pull_request | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $1}'`
#    code_review_id=`echo $all_pull_request | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $4}'`
    all_url=${url}::::${all_url}
#    all_code_review_id=${code_review_id}::::${all_code_review_id}
    
    user=`echo $all_pull_request | awk -v j=$i -F "${epic}"  "{print $j}" | awk -F " " '{print $2}'`
    echo $url
    branch=${user#*:}
    echo $branch
    repo_name=`echo $url | awk -F "https://api.github.com/repos/zstackio/" '{print $2}' | awk -F "/pulls" '{print $1}'`
    
    pull_num=`echo $url | awk -F "pulls/" '{print $2}'`
    echo $repo_name
    if [ "$repo_name" == "zstack-utility"  ];then
        echo $zstack-utility
        ZSTACK_UTILITY="${pull_num} ${branch}"
        echo $ZSTACK_UTILITY
    fi
    
    if [ "$repo_name" == "zstack"  ];then
        echo $zstack
        ZSTACK="${pull_num} ${branch}"
        echo $ZSTACK
    fi
    
    if [ "$repo_name" == "zstack-agent"  ];then
        echo $ZSTACK_AGENT
        ZSTACK_AGENT="${pull_num} ${branch}"
        echo $ZSTACK_AGENT
    fi
    
    if [ "$repo_name" == "zstack-vyos"  ];then
        echo $ZSTACK_VYOS
        ZSTACK_VYOS="${pull_num} ${branch}"
        echo $ZSTACK_VYOS
    fi
    if [ "$repo_name" == "zatack-dashboard"  ];then
        echo $ZSTACK_DASHBOARD
        ZSTACK_DASHBOARD="${pull_num} ${branch}"
        echo $ZSTACK_DASHBOARD
    fi
    if [ "$repo_name" == "premium"  ];then
        echo $PREMIUM
        PREMIUM="${pull_num} ${branch}"
        echo $PREMIUM
    fi
    if [ "$repo_name" == "zstack-store"  ];then
        echo $ZSTACK_STORE
        ZSTACK_STORE="${pull_num} ${branch}"
        echo $ZSTACK_STORE
    fi
    if [ "$repo_name" == "zstack-distro"  ];then
        echo $ZSTACK_DISTRO
        ZSTACK_DISTRO="${pull_num} ${branch}"
        echo $ZSTACK_DISTRO
    fi

    if [ "$repo_name" == "mevoco-ui"  ];then
        echo $MEVOCO_UI
        ZSTACK_DISTRO="${pull_num} ${branch}"
        echo $MEVOCO_UI
    fi
    if [[ "$epic_num" == "" ]];then
        break
    fi
done

echo $ZSTACK_UTILITY
echo $zstack
echo $ZSTACK_AGENT
echo $ZSTACK_VYOS
echo $ZSTACK_DASHBOARD
echo $MEVOCO_UI
echo $PREMIUM
echo $ZSTACK_STORE
echo $ZSTACK_DISTRO


bash -ex ${JENKINS_HOME}/code_review_script/rebase_merge_build.sh "${BUILD_TYPE}" "${ZSTACK}" "${ZSTACK_AGENT}" "${ZSTACK_UTILITY}" "${ZSTACK_DASHBOARD}" "${MEVOCO_UI}" "${PREMIUM}" "${ZSTACK_STORE}" "${ZSTACK_VYOS}" "${ZSTACK_DISTRO}" | tee build.log
RET=${PIPESTATUS[0]}
scp build.log ${BUILD_TYPE}/${BUILD_NUMBER}/${BUILD_TYPE}.log || echo ignore
#ssh root@192.168.200.1 "rm -rf /httpd/${BUILD_TYPE}/latest"
#rsync -avz --filter="+ */" --filter="+ *.bin" --filter="- *" --safe-links ${BUILD_TYPE}/ root@172.20.198.234:/var/www/html/mirror/${BUILD_TYPE}  || echo ignore

END_TIME=${SECONDS}
DURATION=`echo "${END_TIME}-${START_TIME}" | bc`
BUILD_USER="lei.liu"
#if [ ${RET} -eq 127 ]; then
#       echo skip
#       exit 1
if [ ${RET} -ne 0 ]; then
        bash -ex ${JENKINS_HOME}/build_script/dev_build_report.sh ${BUILD_USER} ${BUILD_TYPE} ${DURATION} Failure
else
        bash -ex ${JENKINS_HOME}/build_script/dev_build_report.sh ${BUILD_USER} ${BUILD_TYPE} ${DURATION} success
fi
rsync -avz --safe-links ${BUILD_TYPE}/ root@172.20.198.234:/var/www/html/mirror/${BUILD_TYPE}  || echo ignore
build_log_path="http://172.20.198.234/mirror/PR_rebase_build/"${BUILD_NUMBER}/"PR_rebase_build.log"
if [ ${RET} -ne 0 ];then
    echo "Failed build, update mysql"
    num_url=`echo $all_url | awk -F "::::"  '{print NF}'`
    for ((i=1; i < $num_url; i++))
    do
       successfull_url=`echo $all_url | awk -v j=$i -F  "::::"  '{print $j}'`
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILD-FAIL'  where url='${successfull_url}' and code_review_id in (${code_review_id});\""
       if [ $? -ne 0 ];then
           echo "Fail to update mysql test_state as FAILED-BUILD"
           echo $successfull_url
           RET=4
       fi
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"INSERT INTO pull_request_build (url, build_state, log) VALUES ( '${successfull_url}' ,'BUILD-FAIL', '${build_log_path}')\""

    done

fi

if [ ${RET} -eq 0 ];then
    echo "Successfull build, update mysql"
    num_url=`echo $all_url | awk -F "::::"  '{print NF}'`
    for ((i=1; i < $num_url; i++))
    do
       successfull_url=`echo $all_url | awk -v j=$i -F  "::::"  '{print $j}'`
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILD-PASS'  where url='${successfull_url}' and code_review_id in (${code_review_id});\""
       if [ $? -ne 0 ];then
           echo "Fail to update mysql test_state as SUCCESSFULL-BUILD"
           echo $successfull_url
           RET=4
       fi
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"INSERT INTO pull_request_build (url, build_state, log) VALUES ( '${successfull_url}' ,'BUILD-PASS', '${build_log_path}')\""
    done
fi
exit ${RET}
