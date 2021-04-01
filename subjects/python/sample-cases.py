import csv
import sys
import os
import random

file1 = open(sys.argv[1],'r')
numberOfSamples = sys.argv[2]

csv1 = csv.reader(file1,delimiter=",")
csvList =  list(csv1)

# print list(csvList)[5]
samples =random.sample(range(1, len(list(csvList))), int(numberOfSamples))
print samples
fields = list(csvList)[0]
outputFile = "subjects/samples.csv"
# writing to csv file  
with open(outputFile, 'w') as csvfile:  
    # creating a csv writer object  
    csvwriter = csv.writer(csvfile) 
    # writing the fields  
    csvwriter.writerow(fields)
    for sample in samples:
        csvwriter.writerow(list(csvList)[sample])
