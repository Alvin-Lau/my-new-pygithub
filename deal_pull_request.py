#!/usr/bin/env python

from github import *
from slackclient import SlackClient
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import MySQLdb
import smtplib
import thread
import time
import traceback
import os

def send_slack(context):

    SLACK_TOKEN = os.environ.get('SLACK_USER_TOKEN')
    slack_client = SlackClient(SLACK_TOKEN)
    slack_client.api_call(
        "chat.postMessage",
        channel="code-review",
        text=context,
        username='Robot',
    )

def send_email(html):
    msg = MIMEMultipart()
    #mail_host = "smtp.mevoco.com"
    mail_host = "smtp.163.com"
    #mail_user = "lei.liu@mevoco.com"
    mail_user = "zstack@163.com"
    #mail_password = "qaz123@WSX"
    mail_password = "zstack2015"
    msg['Subject'] = "Pull request(s) arrived"
    msg['From'] = mail_user
    #msg['To'] = "lei.liu@mevoco.com"
    you = "test.zstack@mevoco.com,lei.liu@mevoco.com,xin.zhang@mevoco.com"
    #you = "lei.liu@mevoco.com,test.zstack@mevoco.com"
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
        Db = MySQLdb.connect("localhost","root","zstack.mysql.password")
        Cursor = Db.cursor()
        Cursor.execute("use auto_code_review")
    except Exception as e:
        print str(e)
    
    sql_query_new_pull_request  = "SELECT merge_commit_sha, \
                                          url, title, user,  epic from pull_request \
                                          where test_state='NEW'"
    try:
        Cursor.execute(sql_query_new_pull_request)
        new_pull_request_list = Cursor.fetchall()
    
    except Exception as e:
        print str(e)
    
    html_head = """ <html>  <head></head> <body>  """
    context = """<h2>Hi!! New Pull Requst(s)</h2><table border=1> <tr> <th>User</th> <th>Branch</th> <th>Title</th> </tr>"""

    print len(new_pull_request_list)
    if len(new_pull_request_list) == 0:
        return;
    
    text = ""
    for row in new_pull_request_list:
        merge_commit_sha =  row[0]
        url = row[1]
        title = row[2]
        user = row[3]
        epic = row[4]
        pull_number = int(url.split('/')[-1])
        html_url = url.replace("api.", "", 1)
        html_url = html_url.replace("pulls", "pull", 1)
        html_url = html_url.replace("repos/", "", 1)
    
        print user
        print title

        text = text + epic + "\n>" + "User: " + user + "\n><" + html_url + "|" + title + ">\n\n\n"
        context = context + "<tr><td>" + user + "</td><td>" + epic + "</td><td> <a href=" + html_url + ">"  + title  + "</a></td></tr>"
        
        sql_update_epic = "UPDATE pull_request SET test_state='NOTIFIED_1' \
                           where merge_commit_sha='" + merge_commit_sha + "'"
        try:
            Cursor.execute(sql_update_epic)
            Db.commit()                                                 
        except:                                                         
            Db.rollback()      
    Db.close()
    
    html_end = """ </table></body> </html>"""
    html = html_head + context + html_end
    send_email(html)
    send_slack(text)

if __name__ == '__main__':

    main()
