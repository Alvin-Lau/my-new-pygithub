#!/usr/bin/bash
 
# chkconfig: - 85 15
# description: run_code_merge is for code review merge
#export repo_list="zstackorg/zstack-utility zstackorg/zstack zstackorg/zstack-vyos zxwing/zstack-store zxwing/premium zxwing/mevoco-ui zstackorg/zstack-woodpecker"
export repo_list="zstackorg/zstack-utility zstackorg/zstack zstackorg/zstack-vyos zxwing/zstack-store zxwing/premium zxwing/mevoco-ui zstackorg/zstack-woodpecker"
repo_list="zstackorg/zstack-utility zstackorg/zstack zstackorg/zstack-vyos zxwing/zstack-store zxwing/premium zxwing/mevoco-ui zstackorg/zstack-woodpecker"
#ps -ef | grep "cherry-pick" | grep -v "color=auto" | grep "cherry-pick"
#if [ $? -ne 1 ];then
#    exit 0
#fi
#export repo_list="LeiLiu1991/test_auto LeiLiu1991/test_auto_2 LeiLiu1991/test_auto_3"
#export repo_list="LeiLiu1991/test_auto"
# Alvin-Lau token
#export GITHUB_API_TOKEN="f4d99a92cf913468bc168173cb6c9ac78c85c2e2"
GITHUB_API_TOKEN="f4d99a92cf913468bc168173cb6c9ac78c85c2e2"

# leiliu toke
#export GITHUB_API_TOKEN="${GITHUB_API_TOKEN}"
#GITHUB_API_TOKEN="87ded860feb6f432a5d2567e181858b7cf118fb9"

#slack token
export SLACK_USER_TOKEN="xoxp-16588718595-94852999572-120140093584-cd8141b5e434d253204c23f05f240eef"

#pip install pygithub 
#pip install slackclient
#apt-get install jq

#python ${JENKINS_HOME}/code_review_script/merge_pull_request.py

build_home_path="/root/code_review_script"
DB_USER="root"
DB_IP="172.20.198.222"
DB_PASSWD="password"
DB_NAME="auto_code_review"
sql="select code_review_id, base_commit_sha, url, ref_repo, milestone, epic from pull_request where test_state=\"NEW\" ORDER BY code_review_id DESC LIMIT 1"
ret=$(mysql -u $DB_USER -h ${DB_IP} -p${DB_PASSWD} $DB_NAME -e "$sql");

function git_cherry_pick()
{
    pull_request=$*
    # which branch should cherry-pick
    milestone_title=`echo $pull_request | jq ".milestone.title"`
    milestone_title=${milestone:1:0-1}
    # base sha for cherry-pick
    base_sha=`echo $pull_request | jq ".base.sha"`
    echo $pull_request > affff
    base_sha=${base_sha:1:0-1}
    remote_branch=`echo $pull_request | jq ".head.label"`
    remote_branch_origin=${remote_branch:1:0-1}
    echo "$remote_branch"
    remote_branch=${remote_branch_origin#*:}
    author=${remote_branch_origin%:*}
    echo "cccccccccccccccccccccccccccccccccc"
    echo $author
    echo "cccccccccccccccccccccccccccccccccc"
    author_email=`curl -s -H "Authorization: token ${GITHUB_API_TOKEN}" https://api.github.com/users/$author | jq ".email"`
    author_email=${author_email:1:0-1}
    echo "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    echo $author_email
    echo "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    if [ "$author_email" == null ];then
       author_email=lei.liu@mevoco.com
    fi
    # The author repo, for comparing to get commit that need to be cherry-pick
    head_repo_git_url=`echo $pull_request | jq ".head.repo.ssh_url"`
    # which repo should merge this pull request
    repo_name=`echo $pull_request | jq ".base.repo.name"`
    cd $build_home_path/build/${repo_name:1:0-1}


    git remote remove for-cherry-pick
    git remote add for-cherry-pick ${head_repo_git_url:1:0-1}
    git fetch
    git fetch for-cherry-pick
    git log ${base_sha}..for-cherry-pick/${remote_branch}
    git log ${base_sha}..for-cherry-pick/${remote_branch}  | grep commit | sed -e 's/commit//g' >  $build_home_path/tmp_commits || echo "fail to get commit"
    #git branch -a | grep -w $milestone_title | awk -F '/' '{print $NF}' > $build_home_path/tmp_target_branch 
    target_branch=${milestone_title}.x
    
    echo `pwd`
    echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    echo $head_repo_git_url >> ${build_home_path}/tmp_cherry-pick 2>$1
    echo $milestone_title >> ${build_home_path}/tmp_cherry-pick 2>&1
    echo $base_sha >> ${build_home_path}/tmp_cherry-pick 2>&1
    echo $remote_branch >> ${build_home_path}/tmp_cherry-pick 2>&1
    echo $repo_name >> ${build_home_path}/tmp_cherry-pick 2>&1
    echo $target_branch >> ${build_home_path}/tmp_cherry-pick 2>&1
    git checkout ${target_branch} || git checkout -b ${target_branch}
    git reset --hard origin/$target_branch || echo "fail to reset"
    rm -rf ${build_home_path}/tmp_cherry-pick_log
    for commit in `tac ${build_home_path}/tmp_commits`
    do
         git cherry-pick $commit  >> ${build_home_path}/tmp_cherry-pick_log 2>&1
    done 
    git push origin $target_branch:$target_branch  >> ${build_home_path}/tmp_cherry-pick_log 2>&1
    sleep 5
    echo "mail -s \"cherry pick\" ${author_email} < ${build_home_path}/tmp_cherry-pick_log "
    mail -s "Cherry Pick" ${author_email} < "${build_home_path}/tmp_cherry-pick_log" 

}

function merge_pull_request()
{
    sleep 5
    pull_request=$*
    #whether need to cherry-pick
    milestone=`echo $pull_request | jq ".milestone.title"`

    # the url to merge this pull request
    merge_url=`echo $pull_request | jq "._links.self.href"`
    merge_url=${merge_url:1:0-1}/merge
    title=`echo $pull_request | jq ".title"`

    if [ "$milestone" == null ];then
        echo $merge_url
        echo "adfasdfsdfdsafsadfsafasd"
        merge_message=`curl -s "$merge_url" -XPUT -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Accept: application/vnd.github.polaris-preview" -d "{  \"merge_method\": \"rebase\",  \"commit_title\": \"${title:1:0-1}\"}"`
        echo $merge_message
    else
        git_cherry_pick $pull_request
        merge_message=`curl -s "$merge_url" -XPUT -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Accept: application/vnd.github.polaris-preview" -d "{  \"merge_method\": \"rebase\",  \"commit_title\": \"${title:1:0-1}\"}"`
        echo $merge_message
        echo "merge & cherry-pick"
    fi
    successfully_merge=`echo $merge_message | jq ".merged"`
    if [ "$successfully_merge" != "true" ];then

        merge_message=`curl -s "$merge_url" -XPUT -H "Authorization: token ${GITHUB_API_TOKEN}" -H "Accept: application/vnd.github.polaris-preview" -d "{  \"merge_method\": \"merge\",  \"commit_title\": \"${title:1:0-1}\"}"`
    fi 


}

function deal_pull_request()
{
    #a=`curl -s https://api.github.com/repos/LeiLiu1991/test_auto/pulls?state="open"`

    pull_requests=`curl -s -H "Authorization: token ${GITHUB_API_TOKEN}" $1`
    
    json_length=`echo $pull_requests | jq 'length'`

    for i in `seq $json_length`
    do
        j=`expr $i - 1`
    
        cd $build_home_path
        # Get pull request json
        pull_request_url=`echo $pull_requests | jq ".[$j]._links.self.href"`
        pull_request=`curl -s -H "Authorization: token ${GITHUB_API_TOKEN}" ${pull_request_url:1:0-1}`
    


        echo $pull_request_url
        # the url to get this pull request labels
        issue_url=`echo $pull_request| jq "._links.issue.href"`
        labels_url=${issue_url:1:0-1}/labels
        mergeable=`echo $pull_request |jq ".mergeable"`

        if [ "$mergeable" == "false" ];then
            echo $pull_request_url
            echo "un mergeable"
            continue
        fi
        #echo $labels_url
    
        if [ "$labels_url"  == null ];then
            continue
        fi
    
        labels=`curl -s -H "Authorization: token ${GITHUB_API_TOKEN}" ${labels_url}`
        #echo $labels
        labels_length=`echo $labels | jq 'length'`
        flag=false
    
        for m in `seq $labels_length`
        do
            n=`expr $m - 1`
            label=`echo $labels | jq ".[$n].name"`
            if [ "${label:1:0-1}" == "REVIEWED-BY-MAINTAINER" ];then
                 flag=true
            fi
            #echo $flag
        done
        if [  "$flag" == "false" ];then
            echo "continue"
            continue
        fi 
        # to judgement whether it's an epic patch


    
        epic=`echo $pull_request | jq ".head.label"`
        multi_repo=`echo ${epic:1:0-1} | awk -F '@@' '{print $2}'`
        if [ "$multi_repo" == "" ];then
            multi_repo=0
        fi
        
        if [ ${multi_repo} -lt 2 ];then
            echo "first merge"
            merge_pull_request  $pull_request
        fi
    
        if [ ${multi_repo} -gt 1 ];then
            
            #need check whether it's mergealbe
            echo "," >> tmp_json_file 
            echo ${epic:1:0-1} >> tmp_epic_file
            echo "$pull_request" >> tmp_json_file
        fi
    done
}

echo "Start"
echo "[{}" > tmp_json_file
rm -f tmp_epic_file
for repo in $repo_list
do
    pull_request_url=https://api.github.com/repos/$repo/pulls?state=\"open\"
    deal_pull_request $pull_request_url
done
cd $build_home_path 
echo "]" >> tmp_json_file

epic_length=`cat tmp_json_file | jq "length"`
for epic in `sort -k2n tmp_epic_file | uniq`
do
    multi_repo_num=`echo ${epic} | awk -F '@@' '{print $2}'`
    pull_requests=`cat tmp_json_file | jq "map(select(.head.label == \"$epic\"))"`
    ready_pull_request_num=`echo $pull_requests | jq "length"`
    #echo $multi_repo_num
    #echo $ready_pull_request_num
    if [ "$multi_repo_num" -le "$ready_pull_request_num" ];then

        for i in `seq $ready_pull_request_num`
        do
            j=`expr $i - 1`
            epic_pull_request=`echo $pull_requests | jq ".[$j]"`
            merge_pull_request  $epic_pull_request
        done
    fi

done
