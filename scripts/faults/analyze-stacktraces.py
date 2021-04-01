import sys,os
import csv
import re

dir_path = os.path.dirname(os.path.realpath(__file__))
root_path = os.path.join(dir_path,"..","..")
data_path = os.path.join(root_path,"data")
subjects_csv=os.path.join(root_path, "subjects", "subjects.csv")
configurations_csv=os.path.join(root_path,"configurations","configurations.csv")


def collect_stacktraces_in_file(current_test_execution_path):
    collected_stacktraces=[]
    active_stacktrace=False
    next_line_is_exception=False
    current_stacktrace = []

    if not os.path.exists(current_test_execution_path):
        print current_test_execution_path+ " does not exist"
        return collected_stacktraces
    for line in open(current_test_execution_path):
        if ") test" in line:
            if active_stacktrace and len(current_stacktrace) != 1:
                if "StackOverflowError" not in current_stacktrace[0]:
                    print "Still an active stacktrace in captured exceptions >> "+line
                    collected_stacktraces.append(current_stacktrace)
                else:
                    collected_stacktraces.append(current_stacktrace)
                    
            
            testNumber=line.split(") ")[1].split("(")[0]
            active_stacktrace=True
            next_line_is_exception=True
            current_stacktrace = []
            continue
        
        if next_line_is_exception:
            next_line_is_exception=False
            if "evosuite" in line or "TestTimedOutException" in line:
                active_stacktrace=False
                continue
            if len(current_stacktrace) != 0:
                print "Current captured stacktrace is not empty before detecting the exception type >> "+current_test_execution_path
                exit()
            exceptionType=line.split(":")[0]
            
            current_stacktrace.append(re.sub(r"[\n\t\s]*", "", exceptionType))
            continue

        if line.startswith("	at"):
            if not active_stacktrace:
                    continue
            if len(current_stacktrace) == 0:
                    print "Missing exceptionType in captured exception >> "+line
                    exit()
            # Remove frames without line number
            tempstr=line.split("(")[1].split(")")[0].split(":")

            current_frame=line.split("	at ")[1]
                
            if "_ESTest.java" in current_frame:   
                #We should save the current stacktrace and close the active stacktrace
                collected_stacktraces.append(current_stacktrace)
                active_stacktrace=False
            elif len(tempstr) <= 1:
                continue
            elif active_stacktrace:
                current_stacktrace.append(re.sub(r"[\n\t\s]*", "", current_frame))
            continue

    return set(tuple(i) for i in collected_stacktraces)       
    
                


            

                
finalCSVDir = os.path.join(data_path,"captured_exceptions.csv")
finalCSVFile = open(finalCSVDir,"wb")
finalCSVFWriter = csv.writer(finalCSVFile)
fieldnames = ['tool', 'execution_id','project', 'target_class', 'captured',"isAssertion"]
finalCSVFWriter.writerow(fieldnames)

with open(subjects_csv, 'r') as _filehandler:
    csv_file_reader = csv.DictReader(_filehandler)
    for row in csv_file_reader:
        target_class=row["target_class"]
        project_id=row["project_id"]
        bug_id=row["bug_id"]

        project_name=project_id+"-"+bug_id
        
        bug_exposing_stacktraces_path=os.path.join(root_path,"subjects","buggy-versions",project_name,"stacktraces.txt")

        #Check if the stacktrace is an assetion failure
        active_stacktrace=False
        next_line_is_exception=False
        # is_assertion_failure=False
        bug_exposing_stacktraces=[]
        current_bug_exposing_stacktrace=[]
        failing_test=""
        for line in open(bug_exposing_stacktraces_path):
            if line.startswith("--- "):
                if active_stacktrace:
                    print "we are still dealing with an active stacktrace! >> "+project_name
                    exit()
                active_stacktrace=True
                next_line_is_exception=True
                current_bug_exposing_stacktrace=[]
                # is_assertion_failure=False
                failing_test=line.split("--- ")[1].split("::")[0]
                
                continue

            if next_line_is_exception:
                if "AssertionFailedError" in line:
                    # we ignore assertion_failures
                    # is_assertion_failure=True
                    active_stacktrace=False
                else:
                    # is_assertion_failure=False
                    if len(current_bug_exposing_stacktrace) > 0:
                        print "Curren stacktrace should be empty >> "+project_name
                        exit()
                    exceptionType=line.split(":")[0]
                    current_bug_exposing_stacktrace.append(re.sub(r"[\n\t\s]*", "", exceptionType))
                
                next_line_is_exception=False

            
            if line.startswith("------------------"):
                if active_stacktrace:
                    if "StackOverflowError" not in current_bug_exposing_stacktrace[0]:
                        print "Active stacktrace at the end of the stacktrace >> "+project_name
                        bug_exposing_stacktraces.append(current_bug_exposing_stacktrace)
                    else:
                        bug_exposing_stacktraces.append(current_bug_exposing_stacktrace)
                        
                active_stacktrace=False
                failing_test=""
                continue
            
            if line.startswith("	at"):
                if not active_stacktrace:
                    continue

                if failing_test == "":
                    "Empty failing test >> "+ project_name
                    exit()
                if len(current_bug_exposing_stacktrace) == 0:
                    print "Missing exceptionType"
                    exit()
                
                # Remove frames without line number
                tempstr=line.split("(")[1].split(")")[0].split(":")
                if len(tempstr) <= 1:
                    continue

                current_frame=line.split("	at ")[1]
                
                if failing_test in current_frame:
                    
                    #We should save the current stacktrace and close the active stacktrace
                    bug_exposing_stacktraces.append(current_bug_exposing_stacktrace)
                    active_stacktrace=False
                elif active_stacktrace:
                    current_bug_exposing_stacktrace.append(re.sub(r"[\n\t\s]*", "", current_frame))

                continue

            if line.startswith("Caused by:"):
                # Reset current stacktrace
                current_bug_exposing_stacktrace = []
                # And add a the new exceptiontype
                exceptionType=line.split(": ")[1]
                current_bug_exposing_stacktrace.append(re.sub(r"[\n\t\s]*", "", exceptionType))


        # if len(bug_exposing_stacktraces) == 0:
        #     print "No stacktrace without assertion failure"
        #     continue
        
        unique_bug_exposing_stacktraces=set(tuple(i) for i in bug_exposing_stacktraces)
        print str(len(unique_bug_exposing_stacktraces))+" stacktraces detected."
        # for st in unique_bug_exposing_stacktraces:
        #     for f in st:
        #         print f
        #     print "*****"

        print "Comparing the detected stacktraces with the captured exceptions by the automatically generated tests"


        with open(configurations_csv, 'r') as _filehandler2:
            csv_file_reader2 = csv.DictReader(_filehandler2)
            for config_row in csv_file_reader2:
                configuration_name = config_row["configuration_name"]
                print "Configuration: "+configuration_name

                test_execution_results_path=os.path.join(root_path,"data","test-execution-results")

                for execution_id_int in range(1,31):
                    execution_id=str(execution_id_int)
                    print "Round: "+execution_id
                    
                    if len(unique_bug_exposing_stacktraces) ==0:
                        row=[configuration_name,execution_id,project_name,target_class,0,1]
                        finalCSVFWriter.writerow(row)
                        continue
                    
                    current_test_execution_dir_name=project_name+"-"+target_class+"-"+execution_id
                    current_test_execution_path=os.path.join(test_execution_results_path,current_test_execution_dir_name,configuration_name+".txt")

                    current_captured_exceptions=collect_stacktraces_in_file(current_test_execution_path)
                    
                    print "captured exceptions are "+str(len(current_captured_exceptions))


                    # for st in current_captured_exceptions:
                    #     for f in st:
                    #         print f
                    #     print "~~~~~~~~~~~~~~~~~~~~~~~~"

                    # TODO: Compare current_captured_exceptions and aunique_bug_exposing_stacktraces
                    found=False
                    for exst in unique_bug_exposing_stacktraces:
                        found=False
                        for capst in current_captured_exceptions:
                            exposing_stacktraces_size=len(exst)
                            captured_exceptions_size=len(capst)
                            minimum_size=min(exposing_stacktraces_size,captured_exceptions_size)
                            equal=True
                            for index in range(0,minimum_size):
                                if exst[index] != capst[index]:
                                    equal=False
                                    break
                            if equal:
                                found=True
                                break
                        if found:
                            row=[configuration_name,execution_id,project_name,target_class,1,0]
                            finalCSVFWriter.writerow(row)
                            print "Found. Config "+configuration_name+" round "+execution_id
                            break
                    if not found:
                        row=[configuration_name,execution_id,project_name,target_class,0,0]
                        finalCSVFWriter.writerow(row)
                        print "NOT Found. Config "+configuration_name+" round "+execution_id
                    
                                    

                                






                    







        
            

                

            
