import sys,os
import csv
import shutil

dir_path = os.path.dirname(os.path.realpath(__file__))
root_path = os.path.join(dir_path,"..","..")
data_path = os.path.join(root_path,"data")
configuration_path= os.path.join(root_path,"configurations","configurations.csv")


with open(configuration_path) as f:
    reader = csv.reader(f)
    configs = list(reader)
    configs.pop(0)

first_round = 1
last_round = 30

with open(os.path.join(root_path, "subjects", "subjects.csv"), 'r') as _filehandler:
    csv_file_reader = csv.DictReader(_filehandler)
    for row in csv_file_reader:
        target_class=row["target_class"]
        project=row["project_id"]
        bug_id=row["bug_id"]

        for conf in configs:
            config_name=conf[0]
            for execution_id in range(first_round,last_round+1):
                generatedTestRoot=os.path.join(root_path,"results",project+"-"+bug_id,target_class,config_name,"tests",str(execution_id))
                print ("Going to test "+ generatedTestRoot)
                for root, dirs, files in os.walk(generatedTestRoot):
                    for file in files:
                        if file.endswith("_ESTest.java"):
                            print ("Opening test file: "+file)
                            pattern='fail("Expecting exception: '
                            testInitPattern="public void test"
                            testNumber=-1
                            hasException=False
                            for line in open(os.path.join(root, file),'r'):
                                if testInitPattern in line:
                                    testNumber+=1
                                if pattern in line:
                                    hasException=True
                                    exceptionType=line.split(pattern)[1].split('");')[0]
                                    print ("tool: "+config_name+" test"+str(testNumber)+"() -> "+exceptionType)
                                    finalRow = [config_name, str(execution_id), project+"-"+bug_id, target_class, "test"+str(testNumber), exceptionType]
                                    # exceptionListWriter.writerow(finalRow)

                            if hasException:
                                src=generatedTestRoot
                                dst=os.path.join(root_path,"tests-without-trycatch",project+"-"+bug_id,target_class,config_name,str(execution_id))
                                print ("Copy "+src+" to "+dst)

                                if os.path.isdir(dst):
                                    shutil.rmtree(dst)

                                shutil.copytree(src, dst)
                                
                                # Remove try/catches
                                classPath=root.split("/"+str(execution_id)+"/")[1]
                                classToModify=os.path.join(dst,classPath,file)
                                print ("Remove try catch from "+classToModify)

                                with open(classToModify, 'r') as file:
                                    data = file.readlines()
                                
                                modifiedData = []
                                inCatch=False
                                for line in data:
                                    if inCatch:
                                        if " }\n" in line:
                                            inCatch=False
                                        modifiedData.append("//"+line)
                                        continue
                            
                                    if "} catch(" in line:
                                        inCatch=True
                                        modifiedData.append("//"+line)
                                        continue

                                    if "fail(" in line:
                                        modifiedData.append("//"+line)
                                        continue

                                    if "try {" in line:
                                        modifiedData.append("//"+line)
                                        continue

                                    modifiedData.append(line)
                                with open(classToModify, 'w') as file:
                                    file.writelines(modifiedData)
