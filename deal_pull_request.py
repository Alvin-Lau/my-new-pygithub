#!/usr/bin/env python

from github import *
import MySQLdb
import time

Git = Github("Alvin-Lau", "")
Repo = Git.get_repo("LeiLiu1991/test_auto")
Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
Cursor = Db.cursor()
#Last_round_pull_id_list = []

def apply_single_patch(url):

def apply_epic_patches(url):

def main():

    Cursor.execute("use auto_code_review")

    #Just leave this. Revisite is needed
    #sql_create_table = 'create table if not exists pull_request( \
    #                           code_review_id INT NOT NULL AUTO_INCREMENT, \
    #                           merge_commit_sha CHAR(64), \
    #                           url VARCHAR(170) NOT NULL, \
    #                           epic VARCHAR(100), \
    #                           test_state CHAR(30) NOT NULL, \
    #                           updated_at datetime, \
    #                           PRIMARY KEY(code_review_id) \
    #                           )'
    #Cursor.execute(sql_create_table)

    while True:
         

        sql_query_new_pull_request  = "SELECT merge_commit_sha, \
                                              url, epic from pull_request \
                                              where test_state='NEW'"
        Cursor.execute(sql_query_new_pull_request)
        new_pull_request_list = Cursor.fetchall()

        for row in new_pull_request_list:
            merge_commit_sha =  row[0]
            url = row[1]
            epic = row[2]
            
            if epic.find("@@") == -1
                apply_single_patch(url)
            else
                sql_update_record = "UPDATE pull_request SET test_state='READY' \
                                             where merge_commit_sha='"  + merge_commit_sha + "'" 
                try:
                    Cursor.execute(sql_update_record)
                    Db.commit()
                except:
                    Db.rollback()
                apply_epic_patches(epic)

if __name__ == '__main__':
    main()
