import sys,os
import csv

dir_path = os.path.dirname(os.path.realpath(__file__))
root_path = os.path.join(dir_path,"..","..")

final_csv_dir = os.path.join(root_path,"data","bbc_triggered.csv")
final_csv_file = open(final_csv_dir,"wb")
final_csv_writer = csv.writer(final_csv_file)

fields = ["project_id","bug_id","target_class","execution_id","objective","objective_type","called","activated","useful","ff_eval"]
final_csv_writer.writerow(fields)
with open(os.path.join(root_path, "subjects", "subjects.csv"), 'r') as _filehandler:
    csv_file_reader = csv.DictReader(_filehandler)
    for row in csv_file_reader:
        target_class = row["target_class"]
        project_id = row["project_id"]
        bug_id = row["bug_id"]
        
        logs_dir = os.path.join(root_path, "results", project_id+"-"+bug_id, target_class, "BBC-F0-100", "logs")
        print "Analyzing logs in "+logs_dir
        for execution_id in range(1,31):
            log_file_path = os.path.join(logs_dir,str(execution_id))
            log_file = open(log_file_path)
            for line in log_file:
                if line.startswith("Number of times BBC is called, activated, and useful for "):
                    interesting_substring = line.split("Number of times BBC is called, activated, and useful for ")[1]
                    temp_arr = interesting_substring.split("| Number of FF evals: ")
                    ff_eval = temp_arr[1].strip()
                    interesting_substring = temp_arr[0]
                    index = interesting_substring.rfind(':')
                    objective_name = interesting_substring[:index]
                    triggered_data = interesting_substring[index+1:].strip()
                    temp_arr = triggered_data.split(",")
                    called = temp_arr[0]
                    activated = temp_arr[1]
                    useful = temp_arr[2]

                    objective_type = "Line"

                    if "Branch" in objective_name:
                        objective_type = "Branch"

                    new_row = [project_id,bug_id,target_class,execution_id,objective_name,objective_type,called,activated,useful,ff_eval]
                    final_csv_writer.writerow(new_row)



final_csv_file.close()