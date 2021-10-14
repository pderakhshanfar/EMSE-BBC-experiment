
# Add new separator
OLDIFS=$IFS
IFS=,

# number of parallel processes
LIMIT=$1
FirstRound=$2
LastRound=$3
Budget=$4
Mem=$5
CONFIGURATIONS_FILE=$6
INPUT=$7




# Check input CSV file
[ ! -f $INPUT ] && { die "$INPUT file not found"; }

num_classes="$(( $(wc -l < "${INPUT}") - 1 ))"  
num_rounds="$((LastRound - FirstRound + 1))"
num_configs="$(( $(wc -l < "${CONFIGURATIONS_FILE}") - 1 ))"  
num_executions="$(( num_rounds * num_configs * num_classes ))"
echo "number of classes $num_classes, number of rounds $num_rounds, number of configurations $num_configs."
echo "Total number of executions: $num_executions"
echo "Time budget: $Budget"
echo "Memory: $Mem"

if [[ -z $8 ]] || [ ! -d $8 ]; then
  SEED="0"
  echo "**New Experiment**"
else
  SEED=$8
  echo "**Replicating Experiment**"
fi

# # make a directory for used SEED
# if [ -d "results/SEED" ]; then
#   rm -rf "results/SEED"
# fi

need_to_rerun=true
attempt_counter=1
while [ "$need_to_rerun" = true ] ; 
do
    echo "Attempt number $attempt_counter"

    if [[ attempt_counter -eq 4 ]]; then
      break
    fi

    class_counter=0
    new_execution=false
    while read target_class project bug_id
    do
      # skip the title row
      if [[ "$class_counter" -eq "0" ]]; then
        class_counter="$(( class_counter + 1 ))"
        continue
      fi

      project_name=$project-$bug_id
      echo "[$class_counter/$num_classes] Generating tests for class $target_class from project $project_name"

      # Extracting classpath
      project_directory="subjects/buggy-versions/$project_name"
      project_cp="$(cat $project_directory/cp-entries.txt)"

      # Open a nested loop for rounds
      for (( round=FirstRound; round<=LastRound; round++ ))
      do

        #Now, lets begin the final loop on configurations
        configuration_header_passed=0
        while read configuration_name args
          do
            # skip the title row
            if [[ "$configuration_header_passed" -eq "0" ]]; then
              configuration_header_passed="1"
              continue
            fi

            report_dir="results/$project_name/$target_class/$configuration_name/reports/$round"
            # If it is replication of an experiment and this is our first attempt, we remove the report file to make sure that the execution will run again
            if [[ "$SEED" != "0" && attempt_counter -eq 1 ]]; then
              if [ -f "$report_dir/statistics.csv" ]; then
                rm "$report_dir/statistics.csv"
              fi
            fi

            # If reprot is already available
            if [ -f "$report_dir/statistics.csv" ]; then
              echo "Report is already available at $report_dir"
              continue
            else
              new_execution=true
            fi

            echo "Generating test for $target_class using $configuration_name. Round $round/$num_rounds"

            # Extract arguments
            old_ifs="${IFS}"; IFS=' '; read -ra user_configuration_array <<< "${args}"; IFS="${old_ifs}";
            old_processes=$(pgrep -l java | wc -l)
            # Run EvoSuite
            . scripts/run/run_evosuite.sh $round $configuration_name $project_name $project_cp $target_class $Budget $Mem $SEED $user_configuration_array

            # Wait if we reach to the limit
            while (( $(jobs -p | wc -l) >= $LIMIT )); 
            do
              sleep 1
              # wait -n       # Wait for the first sub-process to finish
              # code=$? # Exit code of sub-process
            done

          done < $CONFIGURATIONS_FILE

      done

      # Increase class counter
      class_counter="$(( class_counter + 1 ))"
    done < $INPUT

    if [ "$new_execution" = false ] ; then
      echo 'No new execution'
      need_to_rerun=false
    fi
    attempt_counter="$(( attempt_counter + 1 ))"

    waiting_counter=0
    #After finishing tasks, wait for tools to finish their test generation processes.
    while (( $(pgrep -l java | wc -l) > 0 ))
    do
      if [[ waiting_counter -eq 20 ]]; then
        for PID in $(pgrep java) 
        do
          kill -9 $PID
        done
        break
      fi
      waiting_counter="$(( waiting_counter + 1 ))"
      activeProcesses=$(pgrep -l java | wc -l)
      echo "There are still $activeProcesses active java processes: "
      pgrep -l java
      sleep 60
    done

done


# Generate the final CSV file
# . scripts/csv/generate_final_csv.sh $FirstRound $LastRound $CONFIGURATIONS_FILE $INPUT






    

    

    
      

        





# #After finishing tasks, wait for tools to finish their test generation processes.
# while (( $(pgrep -l java | wc -l) > 0 ))
# do
#   sleep 60
#   # Check if all of the tests are generated
#   finished=true
#   while read tool execution_id project caller_class callee_class
#     do
#       if [[ "$tool" == evosuite-callee* ]]; then
#         resultDir="results/evosuite5/$project-$callee_class-$execution_id"
#       elif [[ "$tool" == evosuite-caller* ]]; then
#         resultDir="results/evosuite5/$project-$caller_class-$execution_id"
#       elif [[ "$tool" == "botsing" ]]; then
#         resultDir="results/$tool/$project-$caller_class-$callee_class-$execution_id"
#       fi

#       if [ ! -d "$resultDir" ]; then
#         echo "$resultDir is not available yet!"
#         finished=false
#         break
#       fi
#     done

#     if [ "$finished" = true ] ; then
#       echo 'Killing all of the processes'
#       kill -9 $(pgrep java)
#     fi
# done

# echo "Process is finished."