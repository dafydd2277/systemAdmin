#!/usr/bin/python3

import sys

def compare_lists(list_a, list_b):
    new_entries = []
    for i in list_a:
        if i not in list_b:
            new_entries.append(i)

    return new_entries

file_newEmails = open(sys.argv[1], "r")
data_newEmails = file_newEmails.read()
list_newEmails = data_newEmails.split("\n")

file_emailList = open(sys.argv[2], "r")
data_emailList = file_emailList.read()
list_emailList = data_emailList.split("\n")


new_entries = compare_lists(list_newEmails,list_emailList)

print('New emails to add:\n')
print(*new_entries, sep='\n')
    
