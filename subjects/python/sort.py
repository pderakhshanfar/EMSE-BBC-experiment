import csv
import sys
import os
import operator

file1 = open(sys.argv[1],'r')

csv1 = csv.reader(file1,delimiter=",")

sort = sorted(csv1,key=operator.itemgetter(1),reverse = True)


project_id = os.path.splitext(os.path.basename(sys.argv[1]))[0]

dir_path = os.path.dirname(os.path.realpath(__file__))
finalList = os.path.join(dir_path,"..","bugs.csv")

outputFile = open(finalList,"a")
outputFileWriter = csv.writer(outputFile)


index=0
while index < len(sort) and index < 10:
    outputFileWriter.writerow([project_id,sort[index][0],sort[index][1],sort[index][2]])
    index+=1


    