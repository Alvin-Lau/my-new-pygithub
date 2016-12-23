#!/usr/bin/env python

from github import *
import MySQLdb
import time

Git = Github("Alvin-Lau", "")
#Last_round_pull_id_list = []

def get_pull(Repo):

    #create database if not exists
    Db = MySQLdb.connect("localhost","root","password")
    Cursor = Db.cursor()
    sql_create_database = 'create database if not exists auto_code_review'
    Cursor.execute(sql_create_database)

    Cursor.execute("use auto_code_review")

    #create table  if not exists
    #code_review_id INT NOT NULL AUTO_INCREMENT,
    sql_create_table = 'create table if not exists pull_request( \
                               code_review_id INT NOT NULL AUTO_INCREMENT, \
                               merge_commit_sha CHAR(64), \
                               url VARCHAR(170) NOT NULL, \
                               epic VARCHAR(100), \
                               test_state CHAR(30) NOT NULL, \
                               updated_at datetime, \
                               PRIMARY KEY(code_review_id) \
                               )'
    Cursor.execute(sql_create_table)

    Pulls_List = Repo.get_pulls()
    
    for pull in Pulls_List:

        merge_commit_sha = str(pull.merge_commit_sha)
        sql_query_sha = "SELECT merge_commit_sha from pull_request \
                         where merge_commit_sha='" + merge_commit_sha +"'"
        num_of_results = Cursor.execute(sql_query_sha)

        #This is a new pull request
                         #                PRIMARY KEY(merge_commit_sha) \
        if num_of_results == 0:
            sql_insert_new_record = "INSERT INTO pull_request( \
                                         merge_commit_sha, \
                                         url, \
                                         epic, \
                                         test_state, \
                                         updated_at \
                                     ) VALUES ('"  + merge_commit_sha + "', '" \
                                         + str(pull.url) + "', '" \
                                         + str(pull.head.label) + "', '" \
                                         + "NEW', '" \
                                         + str(pull.updated_at.strftime('%Y-%m-%d %H:%M:%S')) + "')" 
            try:
                Cursor.execute(sql_insert_new_record)
                Db.commit()
            except:
               Db.rollback()
    Db.close()

def main():

    while True:
        Repo = Git.get_repo("LeiLiu1991/test_auto")
        get_pull(Repo)
        Repo = Git.get_repo("LeiLiu1991/test_auto_2")
        get_pull(Repo)

if __name__ == '__main__':
    main()
