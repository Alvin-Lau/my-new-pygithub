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
    query_add_label_url="select url, merge_commit_sha from pull_request where test_state='BUILD-FAIL'"
    try:
        Cursor.execute(query_add_label_url)
        failed_build_list = Cursor.fetchall()
    except Exception as e:
        print str(e)
    for failed_build in failed_build_list:
        url = failed_build[0]
        merge_commit = failed_build[1]
        print "Build Fail"
        query_build_log = "select build_state, log from pull_request_build where url='" + url + "' and build_state <> 'BUILD-Comment' order by log desc limit 1"
        try:
            Cursor.execute(query_build_log)
            build_log = Cursor.fetchone()
        except Exception as e:
            print str(e)
        if build_log == None:
            build_log = []
            build_log.append("BUILD-PASS")

        if build_log[0] == "BUILD-PASS":
            print "Build log does not math build record, wait next round"
            continue

        log_url = build_log[1]
        repo_name = url.split("/repos/")[1].split("/pulls/")[0]
        pull_num  = int(url.split("/repos/")[1].split("/pulls/")[1])
        Repo = Git.get_repo(repo_name)
        pull = Repo.get_pull(pull_num)
        issue = Repo.get_issue(pull_num)
        try:
            issue.remove_from_labels("BUILD-PASS")
        except Exception as e:
            print str(e)

        try:
            issue.add_to_labels("BUILD-FAIL")
            print "Add BUILD-FAIL label"
        except Exception as e:
            print str(e)

        try:
            pull.create_issue_comment("Build log for merge commit " + merge_commit + ": " + log_url)
            print "Add build log"
        except Exception as e:
            print str(e)

        print url
        print "==================\n"
        mark_build_log = "update pull_request_build set build_state='BUILD-Comment' where url='" + url + "'"
        try:
            Cursor.execute(mark_build_log)
            Db.commit()
        except Exception as e:
            print str(e)


    query_add_label_url = "select url, merge_commit_sha from pull_request where test_state='BUILD-PASS'"
    try:
        Cursor.execute(query_add_label_url)
        passed_build_list = Cursor.fetchall()
    except Exception as e:
        print str(e)
    for passed_build in passed_build_list:
        url = passed_build[0]
        merge_commit = passed_build[1]
        print "Build Pass"
        query_build_log = "select build_state, log from pull_request_build where url='" + url + "' and build_state <> 'BUILD-Comment' order by log desc limit 1"
        try:
            Cursor.execute(query_build_log)
            build_log = Cursor.fetchone()
        except Exception as e:
            print str(e)
        if build_log == None:
            build_log = []
            build_log.append("BUILD-FAIL")
        if build_log[0] == "BUILD-FAIL":
            print "Build log does not math build record, wait next round"
            continue
        log_url = build_log[1]
        repo_name = url.split("/repos/")[1].split("/pulls/")[0]
        pull_num  = int(url.split("/repos/")[1].split("/pulls/")[1])
        Repo = Git.get_repo(repo_name)
        pull = Repo.get_pull(pull_num)
        issue = Repo.get_issue(pull_num)
        try:
            issue.remove_from_labels("BUILD-FAIL")
        except Exception as e:
            print str(e)
        try:
            issue.add_to_labels("BUILD-PASS")
            print "Add BUILD-PASS label"
        except Exception as e:
            print str(e)

        #try:
        #    pull.create_issue_comment("Build log for merge commit " + merge_commit + ": " + log_url)
        #    print "Add build log"
        #except Exception as e:
        #    print str(e)
        print url
        print "==================\n"
        mark_build_log = "update pull_request_build set build_state='BUILD-Comment' where url='" + url + "'"
        try:
            Cursor.execute(mark_build_log)
            Db.commit()
        except Exception as e:
            print str(e)
    Db.close()

if __name__ == '__main__':
    main()
