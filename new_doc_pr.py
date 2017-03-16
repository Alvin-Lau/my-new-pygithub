#!/usr/bin/env python


from github import *
import MySQLdb
import time
import os
import sys

github_token = os.environ["GITHUB_API_TOKEN"]
Git = Github(github_token)
reload(sys)  
sys.setdefaultencoding('utf8')   

def main():

    print "Conneting Mysql"
    Db = MySQLdb.connect(host='172.20.198.222',user='root',passwd='password',port=3306, use_unicode=True, charset="utf8")
    Db.set_character_set('utf8')
    Cursor = Db.cursor()
    Cursor.execute('SET NAMES utf8;')
    Cursor.execute('SET CHARACTER SET utf8;')
    Cursor.execute('SET character_set_connection=utf8;')
    Cursor.execute("use auto_code_review")

    #Repo = Git.get_repo("Alvin-Lau/test")
    Repo = Git.get_repo("zstackio/reference-manual")
    
    sql_query_doc = "SELECT user, pr_url, doc_url, pr_doc_id, body from pull_request_doc where doc_states='NEW' limit 1"

    Cursor.execute(sql_query_doc)
    pull_request_doc_list = Cursor.fetchall()

    for row in pull_request_doc_list:
        issue_assignee = row[0]
        pr_url = row[1]
        pr_doc_id = row[3]
        issue_body = row[4]
        issue_title = pr_url.replace("https://api.github.com/repos/", "https://github.com/")
        issue_title = issue_title.replace("pulls", "pull")
        issue_body = issue_body + "\n" + issue_title

        issue_title = issue_body.replace("@ZStack-Robot", "")[0:20]
        issue = Repo.create_issue(title=issue_title, body=issue_body, assignee=issue_assignee)
        sql_update_doc = "update pull_request_doc set doc_url='" + issue.url + "', doc_states='issued' where pr_doc_id=" + str(pr_doc_id)
        try: 
            Cursor.execute(sql_update_doc)
            Db.commit()
        except Exception as e:
            print "Fail to update mysql or create issue"
            Db.rollback()
            print str(e)

    sql_query_doc = "SELECT user, pr_url, doc_url, pr_doc_id, body from pull_request_doc where doc_states='UPDATED' limit 1"

    Cursor.execute(sql_query_doc)
    pull_request_doc_list = Cursor.fetchall()

    for row in pull_request_doc_list:
        issue_assignee = row[0]
        print issue_assignee
        pr_url = row[1]
        pr_url = 'https://api.github.com/repos/Alvin-Lau/test/pulls/7'
        doc_url = row[2]
        pr_doc_id = row[3]
        issue_body = row[4]
        issue_title = pr_url.replace("https://api.github.com/repos/", "https://github.com/")
        issue_title = issue_title.replace("pulls", "pull")

        if doc_url != None:
            issue_number=doc_url.split("/")[-1]
            print "issue_number"
            print issue_number
            issue = Repo.get_issue(int(issue_number))
            issue.create_comment(issue_body + '\n' + issue_title)

        else:
            issue = Repo.create_issue(title=issue_title, body=issue_body, assignee=issue_assignee)

        try:
            sql_update_doc = "update pull_request_doc set doc_url='" + issue.url + "', doc_states='issued' where pr_doc_id=" + str(pr_doc_id)
            Cursor.execute(sql_update_doc)
            Db.commit()
        except Exception as e:
            Db.rollback()
            print str(e)

    Db.close()

if __name__ == '__main__':
    main()
