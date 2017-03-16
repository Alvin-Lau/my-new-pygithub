#!/usr/bin/bash
set -x

export GITHUB_API_TOKEN="c1b123b0bd510b337865a3b386cb9c6426439688"
export SLACK_USER_TOKEN="xoxp-16588718595-94852999572-120140093584-cd8141b5e434d253204c23f05f240eef"

DB_USER="root"
DB_IP="172.20.198.222"
DB_PASSWD="password"
DB_NAME="auto_code_review"
ssh 172.20.198.222 "mysql -u$DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"create table if not exists cherry_pick( cherry_pick_id INT NOT NULL AUTO_INCREMENT, milestone VARCHAR(20) NOT NULL, url VARCHAR(170) NOT NULL, cherry_pick_log VARCHAR(300) NOT NULL, state CHAR(30) NOT NULL, PRIMARY KEY(cherry_pick_id))\""

function cherry-pick()
{
    cherry_pick_pr=$*
}

function merge_pull_request()
{
    pr_record=$*
    url=`echo $pr_record | awk -F " " '{print $1}'`
    milestone=`echo $pr_record | awk -F " " '{print $3}'`
    epic=`echo $pr_record | awk -F " " '{print $2}'`
    base_sha=`echo $pr_record | awk -F " " '{print $4}'`
    title=`echo $pr_record | awk -F "$base_sha " '{print $2}'`
    title=${title//\"/\\\"}
    echo $url
    echo $milestone
    merge_url=$url/merge
    merge_message=""
    if [ "$milestone" != "000" ];then
        cherry-pick  $pr_record
    else
        merge_message=`curl -s "$merge_url" -XPUT -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Accept: application/vnd.github.polaris-preview" -d "{  \"merge_method\": \"rebase\",  \"commit_title\": \"${title}\"}"`
        echo $merge_message
        echo "Merge" $url
    fi
    successfully_merge=`echo $merge_message | ${JENKINS_HOME}/bin/jq-linux64 ".merged"`

    if [ "$successfully_merge" != "true" ];then
        echo "Fail to rebase merge, try to merge method"
        merge_message=`curl -s "$merge_url" -XPUT -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Accept: application/vnd.github.polaris-preview" -d "{  \"merge_method\": \"merge\",  \"commit_title\": \"${title}\"}"`
    else
        ssh 172.20.198.222 "mysql -u$DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"update pull_request set test_state='merged: $BUILD_NUMBER' where url='$url' \""
    fi

    successfully_merge=`echo $merge_message | ${JENKINS_HOME}/bin/jq-linux64 ".merged"`

    if [ "$successfully_merge" != "true" ];then
        echo "Fail to merged" $url
        #ssh 172.20.198.222 "mysql -u$DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"update pull_request set test_state='Unmergeable: $BUILD_NUMBER' where url='$url' \""
    else
        ssh 172.20.198.222 "mysql -u$DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"update pull_request set test_state='merged: $BUILD_NUMBER' where url='$url' \""
    fi

    echo $url
}

for ((i=0; i<1; i=0))
do
    echo $BUILD_NUMBER
    sql="select distinct url, epic, milestone, base_commit_sha, title from pull_request where test_state='BUILD-PASS' and label like '%REVIEWED-BY-MAINTAINER%' and mergeable='True' LIMIT 1"
    need_merge=$(ssh 172.20.198.222 "mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"$sql\" | awk \"NR>1\"");  
    echo $need_merge
    if [ "$need_merge" = "" ];then
       echo "No more PR need to be merged"
       exit 0
    fi

    #url=`echo $need_merge| awk -F " " '{print $1}'`
    #milestone=`echo $need_merge | awk -F " " '{print $3}'`
    epic=`echo $need_merge | awk -F " " '{print $2}'`

    multi_repo=`echo ${epic} | awk -F '@@' '{print $2}'`

    if [ "$multi_repo" == "" ];then
        multi_repo=0
    fi

    if [ ${multi_repo} -lt 2 ];then
        echo "merge signal repo PR"
        merge_pull_request  $need_merge
    fi

    if [ ${multi_repo} -gt 1 ];then

        sql="select distinct url, epic, milestone, base_commit_sha, title from pull_request where epic='$epic' and label like '%REVIEWED-BY-MAINTAINER%' and mergeable='True' and test_state='BUILD-PASS'" 
        need_merge=$(ssh 172.20.198.222 "mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"$sql\" | awk \"NR>1\"");  
        num_need_merge=`echo $need_merge | awk -F "${epic}"  '{print NF}'`
        if [ $num_need_merge -lt $multi_repo ];then
            echo "Ready epic"
            for ((i=1; i < $num_need_merge; i++))
            do
                need_merge_pr="a b $need_merge"
                try_to_merge_pr=`echo $need_merge_pr | awk -v j=$i -F  "${epic}"  '{print $j}'`
                url=`echo $need_merge_pr | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $1}'`
                echo $url
            done
            sql="select distinct url, epic, milestone, base_commit_sha from pull_request where epic='$epic' and label like '%REVIEWED-BY-MAINTAINER%' and mergeable='True' and test_state='BUILD-FAIL'"
            need_merge_failed_build=$(ssh 172.20.198.222 "mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"$sql\" | awk \"NR>1\"");
            num_need_merge_failed_build=`echo $need_merge_failed_build | awk -F "${epic}"  '{print NF}'`
            for ((i=1; i< $num_need_merge_failed_build; i++))
            do
                  echo "Failed build"
                  echo $need_merge_failed_build | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $1}'
            done

            sql="select distinct url, epic, milestone, base_commit_sha from pull_request where epic='$epic' and label like '%REVIEWED-BY-MAINTAINER%' and mergeable='False' and test_state like 'BUILD-%'"
            need_merge_unmergeable=$(ssh 172.20.198.222 "mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e \"$sql\" | awk \"NR>1\"");
            num_need_merge_unmergeable=`echo $need_merge_unmergeable | awk -F "${epic}"  '{print NF}'`
            for ((i=1; i< $num_need_merge_unmergeable; i++))
            do
                  echo "Unmergeable PR"
                  echo $need_merge_unmergeable | awk -v j=$i -F  "${epic}"  '{print $j}'| awk -F " " '{print $1}'
            done

            echo "Continue to search the pull request which are ready to be merged"
            continue
        else
            for ((i=1; i < $num_need_merge; i++))
            do
                need_merge_pr="$need_merge"
                let m=i+1
                try_to_merge_pr=`echo $need_merge_pr | awk -v j=$m -F  "https://api.github.com/repos/zstackio"  '{print $j}'`
                merge_pull_request https://api.github.com/repos/zstackio$try_to_merge_pr
            done
        fi
        echo ${multi_repo}
        #need check whether it's mergealbe
    fi
done
