import sys,os
import csv

dir_path = os.path.dirname(os.path.realpath(__file__))
root_path = os.path.join(dir_path,"..","..")

final_csv_dir = os.path.join(root_path,"data","objectives_coverages.csv")
final_csv_file = open(final_csv_dir,"wb")
final_csv_writer = csv.writer(final_csv_file)

fields = ["project_id","bug_id","target_class","execution_id","objective","required_time"]
final_csv_writer.writerow(fields)
with open(os.path.join(root_path, "subjects", "samples.csv"), 'r') as _filehandler:
    csv_file_reader = csv.DictReader(_filehandler)
    for row in csv_file_reader:
        target_class = row["target_class"]
        project_id = row["project_id"]
        bug_id = row["bug_id"]
        
        logs_dir = os.path.join(root_path, "results", project_id+"-"+bug_id, target_class, "default", "logs")
        print "Analyzing logs in "+logs_dir
        for execution_id in range(1,31):
            log_file_path = os.path.join(logs_dir,str(execution_id))
            log_file = open(log_file_path)
            for line in log_file:
                if line.startswith("Covered objective: "):
                    data_array = line.split("Covered objective: ")[1].split(", ")
                    new_row = [project_id,bug_id,target_class,execution_id,data_array[0],data_array[1].replace("\n","")]
                    final_csv_writer.writerow(new_row)



final_csv_file.close()