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

def update_pull_request(Db, Cursor, pull, labels):
    print pull
    commit_id = ""
    pull_head_commit = "111"
    try:
        review_comments = pull.get_review_comments()
        index_last_review_commit = len(list(review_comments))
        if index_last_review_commit > 0:
            commit_id = review_comments[index_last_review_commit - 1].original_commit_id
        else:
            commit_id = ""
        pull_head_commit = pull.head.sha
        print "Compare commit id VS pull_head_commit"
        print commit_id
        print pull_head_commit
    except Exception as e:
        print str(e)

    if commit_id == pull_head_commit:
        label="label;;WAITING_PR_UPDATE"
    else:
        label="label;;WAITING_PR_REVIEW"

    print label

    for i in range(0, len(labels)):
        label = label + ";;" + labels[i].name

    if pull.milestone == None:
        milestone = "000"
    else:
        milestone = pull.milestone.title

    try:
        sql_update_record = "UPDATE pull_request SET \
                                 label = '" + label \
                               + "', title= '" + str(pull.title.replace('\'','\\\'')).encode('utf-8')\
                               + "', milestone= '" + milestone\
                               + "', mergeable = '" + str(pull.mergeable) \
                               + "' where url = '" + str(pull.url) + "'"
        print "Update record"
        print "merge_commit_sha: " + str(pull.merge_commit_sha)
        print "base_commit_sha: : " + str(pull.base.sha)
        print "base: : " + str(pull.base.label)
        print "url: " + str(pull.url)
        print "title: " + str(pull.title).encode('utf-8')
        print "label: " + str(label)
        print "ref_repo: " + str(pull.head.repo.ssh_url)
        print "milestone: " + milestone
        print "epic: " + str(pull.head.label)
        print "mergeable: " + str(pull.mergeable)
        print str(pull.head.repo.ssh_url)
 
        print "Update database"
        Cursor.execute(sql_update_record)
        Db.commit()
    except Exception as e:
        Db.rollback()
        print str(e)

def new_doc_record(Db, Cursor, pull):
    try:
        pr_issue_comments = pull.get_issue_comments()
    except Exception as e:
        print str(e)

    for comment in pr_issue_comments:
        try:
            if comment.body.find("@ZStack-Robot") != -1:
                doc_record = "select updated_at from pull_request_doc where id=" + str(comment.id) + " and pr_url='" + str(pull.url) + "'"
                Cursor.execute(doc_record)
                doc_record_results = Cursor.fetchall()
                if len(doc_record_results) == 0:
                    print "New doc record"
                    sql_insert_new_doc_record = "INSERT INTO pull_request_doc( \
                                            merge_commit_sha, \
                                            body, \
                                            id, \
                                            pr_url, \
                                            doc_states, \
                                            user, \
                                            updated_at \
                                            ) VALUES ('" + str(pull.merge_commit_sha) + "', '" \
                                              + str(comment.body.replace('\'','\\\'')).encode('utf-8') + "', '" \
                                              + str(comment.id) + "', '" \
                                              + str(pull.url)  + "', '" \
                                              + "NEW', '" \
                                              + str(pull.user.name) + "', '" \
                                              + str(comment.updated_at.strftime('%Y-%m-%d %H:%M:%S')) + "')"


                elif len(doc_record_results) > 0 and doc_record_results[0][0].strftime('%Y-%m-%d %H:%M:%S') < str(comment.updated_at.strftime('%Y-%m-%d %H:%M:%S')):

                    print "Update doc record"
                    sql_insert_new_doc_record = "update pull_request_doc SET \
                                            body='" + str(comment.body.replace('\'','\\\'')).encode('utf-8')  \
                                            + "', updated_at='" + str(comment.updated_at.strftime('%Y-%m-%d %H:%M:%S')) \
                                            + "', doc_states='UPDATED' where id="  \
                                            + str(comment.id) + " and pr_url='" + str(pull.url) + "'" 
                else:
                    print "No doc pr need to be recorded"
                    continue
                print "merge commit id"
                print str(pull.merge_commit_sha)
                print "comment body encode utf-8"
                print str(comment.body).encode('utf-8')
                print "comment body"
                print str(comment.body)
                print "pull url"
                print str(pull.url)
                str(pull.user.name)
                str(comment.updated_at.strftime('%Y-%m-%d %H:%M:%S'))
               

                try:
                    print "Update database"
                    Cursor.execute(sql_insert_new_doc_record)
                    Db.commit()
                except Exception as e:
                    Db.rollback()
                    print str(e)
            else:
                print "No one @ZStack-Robot, no doc pr"
        except Exception as e:
            Db.rollback()
            print str(e)

def new_pull_request(Db, Cursor, pull, labels):
    print pull
    if pull.milestone == None:
        milestone = "000"
    else:
        milestone = pull.milestone.title

    label="label;;WAITING_PR_REVIEW"

    for i in range(0, len(labels)):
        label = label + ";;" + labels[i].name
     
    try:
        sql_insert_new_record = "INSERT INTO pull_request( \
                                     merge_commit_sha, \
                                     base_commit_sha, \
                                     base, \
                                     url, \
                                     title, \
                                     user, \
                                     label, \
                                     ref_repo, \
                                     milestone, \
                                     epic, \
                                     test_state, \
                                     mergeable, \
                                     updated_at \
                                 ) VALUES ('"  + str(pull.merge_commit_sha) + "', '" \
                                     + str(pull.base.sha) + "', '" \
                                     + str(pull.base.label) + "', '" \
                                     + str(pull.url) + "', '" \
                                     + str(pull.title.replace('\'','\\\'')).encode('utf-8') + "', '" \
                                     + str(pull.user.name) + "', '" \
                                     + str(label) + "','" \
                                     + str(pull.head.repo.ssh_url) + "', '" \
                                     + milestone + "', '" \
                                     + str(pull.head.label) + "', '" \
                                     + "NEW', '" \
                                     + str(pull.mergeable)  + "', '" \
                                     + str(pull.updated_at.strftime('%Y-%m-%d %H:%M:%S')) + "')"
        print "Insert new record"
        print "merge_commit_sha: " + str(pull.merge_commit_sha)
        print "base_commit_sha: : " + str(pull.base.sha)
        print "base: : " + str(pull.base.label)
        print "url: " + str(pull.url)
        print "title: " + str(pull.title).encode('utf-8')
        print "User: " + str(pull.user.name)
        print "label: " + str(label)
        print "ref_repo: " + str(pull.head.repo.ssh_url)
        print "milestone: " + milestone
        print "epic: " + str(pull.head.label)
        print "mergeable: " + str(pull.mergeable)
        print str(pull.head.repo.ssh_url)
        print 

        print "Update database"
        Cursor.execute(sql_insert_new_record)
        Db.commit()
    except Exception as e:
       Db.rollback()
       print str(e)

def get_pull(Repo):

    try:
        print "Conneting Mysql"
        Db = MySQLdb.connect(host='172.20.198.222',user='root',passwd='password',port=3306, use_unicode=True, charset="utf8")
        Db.set_character_set('utf8')
        Cursor = Db.cursor()
        Cursor.execute('SET NAMES utf8;')
        Cursor.execute('SET CHARACTER SET utf8;')
        Cursor.execute('SET character_set_connection=utf8;')
        Cursor.execute("use auto_code_review")

        Pulls_List = Repo.get_pulls()
    except Exception as e:
        print str(e)
        return
    
    for pull in Pulls_List:

        print pull.head.label
        issue_number=pull.url.split("/")[-1]

        try:
            issue = Repo.get_issue(int(issue_number))

            labels = issue.labels
        except Exception as e:
            labels = ""

        merge_commit_sha = str(pull.merge_commit_sha)
        sql_query_sha = "SELECT merge_commit_sha, url from pull_request \
                         where merge_commit_sha='" + merge_commit_sha +"'"
        try:
             num_of_results = Cursor.execute(sql_query_sha)

        except Exception as e:
             print str(e)

        print pull.title
        if num_of_results == 0:
            new_pull_request(Db, Cursor, pull, labels)
        else:
            update_pull_request(Db, Cursor, pull, labels)

        print "Examing doc pr"
        new_doc_record(Db, Cursor, pull)
        print "Examing doc pr done"

    sql_query_pull_request = 'SELECT distinct  url from pull_request where label not LIKE "%REVIEWED-BY-MAINTAINER%" AND test_state not LIKE "closed" AND test_state not LIKE "merged%"'
    try: 
        Cursor.execute(sql_query_pull_request)
        pull_request_list = Cursor.fetchall()
    except Exception as e:
        print str(e)

    for row in pull_request_list:
        pull_request_url = row[0]
        repo_name= pull_request_url.split("https://api.github.com/repos/")[1].split("/pulls")[0]
        if repo_name != Repo.full_name:
            continue
        
        print pull_request_url
        pull_number = int(pull_request_url.split("/")[-1])
        print int(pull_number)
        try:
            tmp_pull = Repo.get_pull(pull_number)
        except Exception as e:
            print "Fail to get pull"
            print pull_number
            print str(e)
            continue

        if tmp_pull.state == "closed" or tmp_pull.state == "merged":
            sql_update_record = "UPDATE pull_request SET \
                                     test_state = '" + tmp_pull.state  \
                                   + "' where url = '" + str(tmp_pull.url) + "'"
            try:
                print "pull request has been closed"
                print tmp_pull
                Cursor.execute(sql_update_record)
                Db.commit()
            except Exception as e:
               Db.rollback()
               print str(e)
    Db.close()

def main():
    #create database if not exists
    #Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
    try:
        Db = MySQLdb.connect(host='172.20.198.222',user='root',passwd='password',port=3306, use_unicode=True, charset="utf8")
        Db.set_character_set('utf8')
        Cursor = Db.cursor()
        Cursor.execute('SET NAMES utf8;')
        Cursor.execute('SET CHARACTER SET utf8;')
        Cursor.execute('SET character_set_connection=utf8;')
        Cursor.execute("use auto_code_review")
        #sql_create_database = 'create database if not exists auto_code_review'
        #Cursor.execute(sql_create_database)
        Db.commit()
    except Exception as e:
        print str(e)

    #create table  if not exists
    #code_review_id INT NOT NULL AUTO_INCREMENT,
    sql_create_table = 'create table if not exists pull_request( \
                               code_review_id INT NOT NULL AUTO_INCREMENT, \
                               merge_commit_sha CHAR(64), \
                               base_commit_sha CHAR(64), \
                               base CHAR(64), \
                               url VARCHAR(170) NOT NULL, \
                               title VARCHAR(170) NOT NULL, \
                               user VARCHAR(100) NOT NULL, \
                               label VARCHAR(200), \
                               ref_repo VARCHAR(300) NOT NULL, \
                               milestone VARCHAR(20) NOT NULL, \
                               epic VARCHAR(100), \
                               test_state CHAR(30) NOT NULL, \
                               mergeable VARCHAR (20) NOT NULL, \
                               updated_at datetime, \
                               PRIMARY KEY(code_review_id) \
                               )'
    try:
        print "Creating pull_request table"
        Cursor.execute(sql_create_table)
        Db.commit()
    except Exception as e:
        Db.rollback()
        print str(e)

    sql_create_table = 'create table if not exists pull_request_doc( \
                               pr_doc_id INT NOT NULL AUTO_INCREMENT, \
                               merge_commit_sha CHAR(64), \
                               body VARCHAR(600), \
                               id INT, \
                               pr_url VARCHAR(170) NOT NULL, \
                               doc_url VARCHAR(170), \
                               user VARCHAR(100) NOT NULL, \
                               status VARCHAR(30), \
                               doc_states VARCHAR (20) NOT NULL, \
                               updated_at datetime, \
                               PRIMARY KEY(pr_doc_id) \
                               )'
    try:
        print "Creating pull_request_doc table"
        Cursor.execute(sql_create_table)
        Db.commit()
    except Exception as e:
        Db.rollback()
        print str(e)

    Db.close()

    for repo in os.environ["repo_list"].split(" "):
        print "\n"
        print repo
        try:
            Repo = Git.get_repo(repo)

        except Exception as e:
            print str(e)
            continue

        get_pull(Repo)
        time.sleep(5)

if __name__ == '__main__':
    main()
