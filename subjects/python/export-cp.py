import sys

cps = sys.argv[1]

arr = cps.split(":")
finalCPsArray = []
for cp in arr:
    if "subjects/buggy-versions" in cp:
        temp = cp.split("/EMSE-BBC-experiment/")[1]
        finalCPsArray.append(temp)
    elif "defects4j/framework" in cp:
        temp = cp.split("defects4j/")[1]
        finalCPsArray.append("defects4j/"+temp)
    else:
        print 0
        exit()

finalContent = ':'.join(finalCPsArray)
print finalContent