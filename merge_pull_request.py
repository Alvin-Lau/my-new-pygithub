#!/usr/bin/env python

from github import *
import MySQLdb
import time

github_token = os.environ["GITHUB_API_TOKEN"]
Git = Github(github_token)

test_auto_pull_list = []


def update_datase_pull_merged(pull):
    merge_commit_sha = str(pull.merge_commit_sha)

    Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
    Cursor = Db.cursor()
    Cursor.execute("use auto_code_review")
    #This is a new pull request
    #PRIMARY KEY(merge_commit_sha) \
    sql_insert_new_record = "INSERT INTO pull_merged( \
                                 merge_commit_sha, \
                                 url, \
                                 epic, \
                                 updated_at \
                             ) VALUES ('"  + merge_commit_sha + "', '" \
                                 + str(pull.url) + "', '" \
                                 + str(pull.head.label) + "', '" \
                                 + str(pull.updated_at.strftime('%Y-%m-%d %H:%M:%S')) + "')" 
    try:
        Cursor.execute(sql_insert_new_record)
        Db.commit()
    except:
       Db.rollback()
    Db.close()

def get_pull(Repo):


    Pulls_List = Repo.get_pulls()
    
    for pull in Pulls_List:
        pull_id = int(pull.url.split('/')[-1])
        issue = Repo.get_issue(pull_id)

        issue_label_name_list = []
        for label in issue.labels:
            issue_label_name_list.append(label.name)

        if pull.head.label.find("@@") == -1:
            #if "Pass" in issue_label_name_list and "Reviewed" in issue_label_name_list:
            if "REVIEWED-BY-MAINTAINER" in issue_label_name_list:
                pull.merge(pull.title)
                update_datase_pull_merged(pull)
        else:
            #if "Pass" in issue_label_name_list and "Reviewed" in issue_label_name_list:
            if "REVIEWED-BY-MAINTAINER" in issue_label_name_list:
                test_auto_pull_list.append(pull)


def main():

    #create database if not exists
    Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
    Cursor = Db.cursor()
    Cursor.execute("use auto_code_review")
#    sql_create_database = 'create database if not exists auto_code_review'
#    Cursor.execute(sql_create_database)
#    Db.commit()
#
#    #create table  if not exists
    #code_review_id INT NOT NULL AUTO_INCREMENT,
    sql_create_table = 'create table if not exists pull_merged( \
                               merge_pull_id INT NOT NULL AUTO_INCREMENT, \
                               merge_commit_sha CHAR(64), \
                               url VARCHAR(170) NOT NULL, \
                               epic VARCHAR(100), \
                               updated_at datetime, \
                               PRIMARY KEY(merge_pull_id) \
                               )'
    Cursor.execute(sql_create_table)
    Db.commit()
    Db.close()

    while True:
        global test_auto_pull_list

        for repo in environ["repo_list"].split(" "):
            print repo
            Repo = Git.get_repo(repo)
            get_pull(Repo)
        print test_auto_pull_list

        pull_epic_list = []

        for pull in test_auto_pull_list:
            pull_epic_list.append(pull.head.label)

        uniqe_pull_epic_list = set(pull_epic_list)


        mergeable_pull_list = []
        for epic in uniqe_pull_epic_list:
            expected_epic_num = int(epic.split("@@")[-1])

            if pull_epic_list.count(epic) == expected_epic_num:

                for pull in test_auto_pull_list:
                    if pull.head.label == epic and pull.mergeable:
                        mergeable_pull_list.append(pull)
                if len(mergeable_pull_list) == expected_epic_num:
                    for pull in mergeable_pull
                            update_datase_pull_merged(pull)
                            pull.merge(pull.title)
                else:
                    

        test_auto_pull_list = []

if __name__ == '__main__':
    main()
