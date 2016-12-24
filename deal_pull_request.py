#!/usr/bin/env python

from github import *
from git import *
import MySQLdb
import thread
import time
import os

def main():

    while True:
        Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
        Cursor = Db.cursor()
        Cursor.execute("use auto_code_review")
        sql_query_new_pull_request  = "SELECT merge_commit_sha, \
                                              url, epic from pull_request \
                                              where test_state='NEW'"
        Cursor.execute(sql_query_new_pull_request)
        new_pull_request_list = Cursor.fetchall()

        for row in new_pull_request_list:
            merge_commit_sha =  row[0]
            url = row[1]
            epic = row[2]
            pull_number = int(url.split('/')[-1])
            
            if epic.find("@@") == -1:
                sql_update_epic = "UPDATE pull_request SET test_state='TESTING' \
                                   where merge_commit_sha='" + merge_commit_sha + "'"
                try:
                    Cursor.execute(sql_update_epic)
                    Db.commit()                                                 
                except:                                                         
                    Db.rollback()      

                #Call Jenkins here
                print "Call Jenkins"
            else:
                sql_query_epic_pull_request = "SELECT url from pull_request \
                                               where epic='"  + epic + "'" 
                epic_count = int(epic.split("@@")[1])
                epic_query_count = Cursor.execute(sql_query_epic_pull_request)
                if int(epic_query_count) < epic_count:
                    continue
                else:
                    epic_url = Cursor.fetchall()
                    epic_results_list = list(set(list(epic_url)))
                    
                    if len(epic_results_list) >= epic_count:
                        sql_update_epic = "UPDATE pull_request SET test_state='EPIC_READY' \
                                           where epic='" + epic + "'"

                        try:
                            Cursor.execute(sql_update_epic)
                            Db.commit()                                                 
                        except:                                                         
                            Db.rollback()      
                        print epic_url
                    else:
                        continue
        Db.close()
        time.sleep(15)

if __name__ == '__main__':

    main()
