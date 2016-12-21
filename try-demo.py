#!/usr/bin/env python

from github import *

Git = Github("Alvin-Lau", "")
Last_round_pull_id_list = []

def newPullArrive(pull):
    print pull.title

def main():
    while True:
    
        Pulls_List = Git.get_repo("LeiLiu1991/test_auto").get_pulls()
    
        This_round_pull_id_list = []
    
        for pull in Pulls_List:
            This_round_pull_id_list.append(pull.id)
    
    
            if pull.id not in Last_round_pull_id_list:
                #deal with new pull request
                print pull.id
                Last_round_pull_id_list.append(pull.id)
                newPullArrive(pull)
    
    
        for last_round_pull in Last_round_pull_id_list:
    
            if last_round_pull not in This_round_pull_id_list:
                Last_round_pull_id_list.remove(last_round_pull)
#        print "This round list:"
#        print This_round_pull_id_list
#        print "last round list:"
#        print Last_round_pull_id_list

if __name__ == '__main__':
    main()
