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
BUILD_TYPE="PR_build"
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

first_pull_request=$(ssh 172.20.198.222 'mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e "select url, ref_repo, epic, base from pull_request where test_state=\"NEW\" limit 1;" |awk "NR>1"');
if [ "$first_pull_request" = "" ];then
    echo "Failure"
    exit 2
fi
epic=`echo $first_pull_request | awk -F " " '{print $3}'`
epic_num=`echo $epic | awk -F "@@" '{print $2}'`
base=`echo $first_pull_request | awk -F " " '{print $4}'`
base_branch=`echo $base | awk -F ":" '{print $2}'`
ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILDING'  where epic='${epic}' and test_state not in ('closed', 'merged');\""
if [ $? -ne 0 ];then
    echo "Fail to update mysql test_state as BUILDING"
    exit 3
fi
all_pull_request=$(ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"select url, ref_repo, epic from pull_request where epic='${epic}' and test_state='BUILDING';\" |awk \"NR>1\"");
num_pull_request=`echo $all_pull_request | awk -F "${epic}"  '{print NF}'`
if [ $epic_num -le $num_pull_request ];then
    echo "There should be more PR"
    ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='NEW'  where epic='${epic}' and test_state='BUILDING';\""
    exit 127
fi

ZSTACK=$base_branch
ZSTACK_AGENT=$base_branch
ZSTACK_UTILITY=$base_branch
ZSTACK_DASHBOARD=$base_branch
MEVOCO_UI=$base_branch
PREMIUM=$base_branch
ZSTACK_STORE=$base_branch
ZSTACK_VYOS=$base_branch
ZSTACK_DISTRO=$base_branch

all_url=""
for ((i=1; i < $num_pull_request; i++))
do
    url=`echo $all_pull_request | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $1}'`
    all_url=${url}::::${all_url}
    repo_ssh=`echo $all_pull_request| awk -v j=$i -F "${epic}"  "{print $j}" | awk -F " " '{print $2}'`
    branch=${epic#*:}
    
    user=`echo $all_pull_request | awk -v j=$i -F "${epic}"  "{print $j}" | awk -F " " '{print $4}'`
    echo $url
    echo $repo_ssh
    echo $branch
    
    repo_name=`basename $repo_ssh`
    repo_name=${repo_name%*\.git}
    echo $repo_name
    if [ $repo_name == "zstack-utility"  ];then
        echo $zstack-utility
        ZSTACK_UTILITY="${repo_ssh} ${branch}"
        echo $ZSTACK_UTILITY
    fi
    
    if [ $repo_name == "zstack"  ];then
        echo $zstack
        ZSTACK="${repo_ssh} ${branch}"
        echo $ZSTACK
    fi
    
    if [ $repo_name == "zstack-agent"  ];then
        echo $ZSTACK_AGENT
        ZSTACK_AGENT="${repo_ssh} ${branch}"
        echo $ZSTACK_AGENT
    fi
    
    if [ $repo_name == "zstack-vyos"  ];then
        echo $ZSTACK_VYOS
        ZSTACK_VYOS="${repo_ssh} ${branch}"
        echo $ZSTACK_VYOS
    fi
    if [ $repo_name == "zatack-dashboard"  ];then
        echo $ZSTACK_DASHBOARD
        ZSTACK_DASHBOARD="${repo_ssh} ${branch}"
        echo $ZSTACK_DASHBOARD
    fi
    if [ $repo_name == "premium"  ];then
        echo $PREMIUM
        PREMIUM="${repo_ssh} ${branch}"
        echo $PREMIUM
    fi
    if [ $repo_name == "zstack-store"  ];then
        echo $ZSTACK_STORE
        ZSTACK_STORE="${repo_ssh} ${branch}"
        echo $ZSTACK_STORE
    fi
    if [ $repo_name == "zstack-distro"  ];then
        echo $ZSTACK_DISTRO
        ZSTACK_DISTRO="${repo_ssh} ${branch}"
        echo $ZSTACK_DISTRO
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


bash -ex ${JENKINS_HOME}/build_script/dev_build.sh "${BUILD_TYPE}" "${ZSTACK}" "${ZSTACK_AGENT}" "${ZSTACK_UTILITY}" "${ZSTACK_DASHBOARD}" "${MEVOCO_UI}" "${PREMIUM}" "${ZSTACK_STORE}" "${ZSTACK_VYOS}" "${ZSTACK_DISTRO}" | tee build.log
RET=${PIPESTATUS[0]}
scp build.log ${BUILD_TYPE}/${BUILD_NUMBER}/${BUILD_TYPE}.log || echo ignore
#ssh root@192.168.200.1 "rm -rf /httpd/${BUILD_TYPE}/latest"
rsync -avz --filter="+ */" --filter="+ *.bin" --filter="- *" --safe-links ${BUILD_TYPE}/ root@172.20.198.234:/var/www/html/mirror/${BUILD_TYPE}  || echo ignore

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
if [ ${RET} -ne 0 ];then
    echo "Failed build, update mysql"
    num_url=`echo $all_url | awk -F "::::"  '{print NF}'`
    for ((i=1; i < $num_url; i++))
    do
       successfull_url=`echo $all_url | awk -v j=$i -F  "::::"  '{print $j}'`
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILD-FAIL'  where url='${successfull_url}';\""
       if [ $? -ne 0 ];then
           echo "Fail to update mysql test_state as FAILED-BUILD"
           echo $successfull_url
           RET=4
       fi

    done

fi

if [ ${RET} -eq 0 ];then
    echo "Successfull build, update mysql"
    num_url=`echo $all_url | awk -F "::::"  '{print NF}'`
    for ((i=1; i < $num_url; i++))
    do
       successfull_url=`echo $all_url | awk -v j=$i -F  "::::"  '{print $j}'`
       ssh 172.20.198.222 "mysql -h172.20.198.222 -uroot -ppassword -D auto_code_review -e \"update pull_request set test_state='BUILD-PASS'  where url='${successfull_url}';\""
       if [ $? -ne 0 ];then
           echo "Fail to update mysql test_state as SUCCESSFULL-BUILD"
           echo $successfull_url
           RET=4
       fi
    done

fi
exit ${RET}
