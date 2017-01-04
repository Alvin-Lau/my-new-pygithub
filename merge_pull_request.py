#!/usr/bin/env python

from github import *
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import MySQLdb
import smtplib
import time
import os


github_token = os.environ["GITHUB_API_TOKEN"]
Git = Github(github_token)

test_auto_pull_list = []

def send_email(html, you):
    me = "lei.liu@mevoco.com"
    msg = MIMEMultipart()
    msg['Subject'] = "One/Several pull request(s) can not be merged"
    msg['From'] = me
    msg['To'] = you
    part2 = MIMEText(html, 'html')
    msg.attach(part2)
    s = smtplib.SMTP('localhost')
    s.sendmail(me, you, msg.as_string())
    s.quit()

def update_database_unmerge_pull_request(epic):

    Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
    Cursor = Db.cursor()
    Cursor.execute("use auto_code_review")
    #This is a new pull request
    #PRIMARY KEY(merge_commit_sha) \
    sql_insert_new_record = "INSERT INTO pull_unmerged( \
                                 epic, \
                             ) VALUES ('"  
                                 + str(pull.head.label) + "')"
    try:
        Cursor.execute(sql_insert_new_record)
        Db.commit()
    except:
       Db.rollback()
    Db.close()


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

    sql_create_table = 'create table if not exists pull_unmerged( \
                               unmerge_pull_id INT NOT NULL AUTO_INCREMENT, \
                               epic VARCHAR(100), \
                               PRIMARY KEY(unmerge_pull_id) \
                               )'
    Cursor.execute(sql_create_table)
    Db.commit()

    Db.close()

    while True:
        global test_auto_pull_list

        for repo in os.environ["repo_list"].split(" "):
            print repo
            Repo = Git.get_repo(repo)
            get_pull(Repo)
        print test_auto_pull_list

        pull_epic_list = []

        for pull in test_auto_pull_list:
            pull_epic_list.append(pull.head.label)

        uniqe_pull_epic_list = set(pull_epic_list)


        mergeable_pull_list = []
        unmergeable_pull_list = []
        for epic in uniqe_pull_epic_list:
            expected_epic_num = int(epic.split("@@")[-1])

            if pull_epic_list.count(epic) == expected_epic_num:

                for pull in test_auto_pull_list:
                    if pull.head.label == epic and pull.mergeable:
                        mergeable_pull_list.append(pull)
                    if pull.head.label == epic not pull.mergeable:
                        unmergeable_pull_list.append(pull)
                if len(mergeable_pull_list) == expected_epic_num:
                    for mergeable_pull in mergeable_pull_list:
                            update_datase_pull_merged(mergeable_pull)
                            mergeable_pull.merge(str(mergeable_pull.title))
                else:
                    epic_unmerged = "SELECT epic from pull_unmerged\
                                where epic='"  + epic + "'"
                    epic_query_count = Cursor.execute(sql_query_epic_pull_request)
                    patches_auther = epic.split(":")[0]
                    github_user = Git.get_user(patches_auther)
                    patches_auther_email = github_user.email

                    if int(epic_query_count) ==  0:
                        html_head = """\
                          <html>
                            <head></head>
                            <body>
                              <p>Hi! Buddy<br>
                        """
                        context = "<h2>Pull requst(s) that can not be merged<\h2>"
                        for pull in unmergeable_pull_list:
                            context = context + "<h3>" + pull.title + "</h3>"

                        context =  context + "<h2>Pull requst(s) that can be merged<\h2>"
                        for pull in mergeable_pull_list:
                            context = context + "<h3>" + pull.title + "</h3>"

                        html_end = """\
                              </p>
                            </body>
                          </html>
                        """
                        html = html_head + context + html_end

                        if patches_auther_email == None:
                            patches_auther_email = "lei.liu@mevoco.com"
                            html = "<html><head></head><body><p>Hi!<br><h2>User: " \
                                   + github_user + " ,don't expose his/her github email" \
                                   + "</h2></p></body></html>"

                        send_email(html, patches_auther_email)
                        update_database_unmerge_pull_request(epic)
                    

        test_auto_pull_list = []

if __name__ == '__main__':
    main()
