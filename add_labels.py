#!/usr/bin/env python

from github import *
from slackclient import SlackClient
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import MySQLdb
import smtplib
import time
import os


github_token = os.environ["GITHUB_API_TOKEN"]
Git = Github(github_token)

def send_slack(context):

    SLACK_TOKEN = os.environ.get('SLACK_USER_TOKEN')
    slack_client = SlackClient(SLACK_TOKEN)
    slack_client.api_call(
        "chat.postMessage",
        channel="code-review",
        text=context,
        username='Robot',
    )

def send_email(html, you):
    msg = MIMEMultipart()
    mail_host = "smtp.163.com"
    mail_user = "zstack@163.com"
    mail_password = "zstack2015"
    msg['Subject'] = "One/Several pull request(s) can not be merged"
    msg['From'] = mail_user
    msg['To'] = you
    part2 = MIMEText(html, 'html')
    msg.attach(part2)
    try:
        print "try to send"
        s = smtplib.SMTP(mail_host, 25)
        s.set_debuglevel(1)
        s.ehlo()
        #s.connect(mail_host)
        #s.connect('localhost')
        s.login(mail_user, mail_password)
        s.ehlo()
        s.sendmail(mail_user, you.split(","), msg.as_string())
    except Exception as e:
        print str(e)
    s.close()


def main():

    try:
        Db = MySQLdb.connect(host='172.20.198.222',user='root',passwd='password',port=3306)
        Cursor = Db.cursor()
        Cursor.execute("use auto_code_review")
        Db.commit()
    except Exception as e:
        print str(e)
    query_add_label_url="select url from pull_request where test_state='BUILD-FAIL'"
    try:
        Cursor.execute(query_add_label_url)
        failed_build_list = Cursor.fetchall()
    except Exception as e:
        print str(e)
    for failed_build in failed_build_list:
        url = failed_build[0]
        print "Build Fail"
        print url
        print "==================\n"

        repo_name = url.split("/repos/")[1].split("/pulls/")[0]
        pull_num  = int(url.split("/repos/")[1].split("/pulls/")[1])
        Repo = Git.get_repo(repo_name)
        pull = Repo.get_pull(pull_num)
        issue = Repo.get_issue(pull_num)
        try:
            issue.add_to_labels("BUILD-FAIL")
            print "Add BUILD-FAIL label"
        except Exception as e:
            print str(e)

    query_add_label_url="select url from pull_request where test_state='BUILD-PASS'"
    try:
        Cursor.execute(query_add_label_url)
        passed_build_list = Cursor.fetchall()
    except Exception as e:
        print str(e)
    for passed_build in passed_build_list:
        url = passed_build[0]
        print "Build Pass"
        print url
        print "==================\n"
        repo_name = url.split("/repos/")[1].split("/pulls/")[0]
        pull_num  = int(url.split("/repos/")[1].split("/pulls/")[1])
        Repo = Git.get_repo(repo_name)
        pull = Repo.get_pull(pull_num)
        issue = Repo.get_issue(pull_num)
        try:
            issue.add_to_labels("BUILD-PASS")
            print "Add BUILD-PASS label"
        except Exception as e:
            print str(e)
    Db.close()

if __name__ == '__main__':
    main()

##print epic
#Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
#Cursor = Db.cursor()
#Cursor.execute("use auto_code_review")
#epic_unmerged = 'SELECT epic from pull_unmerged \
#            where epic="'  + epic + '"'
#epic_query_count = 0
#try:
#    epic_query_count = Cursor.execute(epic_unmerged)
#    Db.commit()
#except:
#   Db.rollback()
#Db.close()
#
#patches_auther = epic.split(":")[0]
#github_user = Git.get_user(patches_auther)
#patches_auther_email = github_user.email
#
#if int(epic_query_count) ==  0:
#    html_head = """<html><head></head><body><p>Hi! Buddy<br></p>"""
#    context = "<h2>Pull requst(s) that can not be merged</h2>"
#    for pull in unmergeable_pull_list:
#        context = context + "<p>" + pull.title + "<br></p>"
#
#    context =  context + "<h2>Pull requst(s) that can be merged</h2>"
#    for pull in mergeable_pull_list:
#        context = context + "<p>" + pull.title + "<br></p>"
#
#    html_end = """</body></html>"""
#    html = html_head + context + html_end
#
#    if patches_auther_email == None:
#        patches_auther_email = "lei.liu@mevoco.com"
#        html = "<html><head></head><body><p>Hi!<br><h2>User: " \
#               + patches_auther + " ,do not expose his/her github email" \
#               + "</h2></p></body></html>"
#
#    send_email(html, patches_auther_email)
#    update_database_unmerge_pull_request(epic)
                    
