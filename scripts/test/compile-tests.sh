INPUT=$1
CONFIGURATIONS_FILE=$2
FirstRound=$3
LastRound=$4
LIMIT=$5

OLDIFS=$IFS
IFS=,

root_dir=$(pwd)
test_execution_cp="$(cat libs/test_execution/classpath.txt)"

[ ! -f $INPUT ] && { echo "$INPUT file not found"; }

# First loop, subjects
class_counter=0
while read target_class project bug_id
do
    # skip the title row
    if [[ "$class_counter" -eq "0" ]]; then
        class_counter="$(( class_counter + 1 ))"
        continue
    fi

    # Prepare project cp
    project_name="$project-$bug_id"
    project_directory="subjects/buggy-versions/$project_name/cp-entries.txt"
    project_cp="$(cat $project_directory)"

    # Second loop, configurations
    configuration_header_passed=0
    while read configuration_name args
    do
        # skip the title row
        if [[ "$configuration_header_passed" -eq "0" ]]; then
            configuration_header_passed="1"
            continue
        fi
        
        # Third loop, execution rounds
        for (( round=FirstRound; round<=LastRound; round++ ))
        do
            # Now, we can do the main task for the current config, subject, and execution round
            current_test_dir="$root_dir/results/tests-without-trycatch/$project_name/$target_class/$configuration_name/$round"
            if [ ! -d "$current_test_dir" ]; then
                echo "$current_test_dir is missing!"
                continue
            fi

            echo "Compiling the test in $current_test_dir"
            echo "Compiling scaffolding tests"
            # for scaffoldingTest in `find "$current_test_dir" -name "*_scaffolding.java" -type f`; do
            #     javac -cp "$project_cp:$test_execution_cp" $scaffoldingTest &
            # done

            # echo "Compiling the main test class"
            for mainTest in `find "$current_test_dir" -name "*_ESTest.java" -type f`; do
            echo $mainTest
                javac -cp "$project_cp:$current_test_dir:$test_execution_cp" $mainTest &
            done

            # Wait if we reach to the limit
            while (( $(jobs -p | wc -l) >= $LIMIT )); 
            do
              sleep 1
              # wait -n       # Wait for the first sub-process to finish
              # code=$? # Exit code of sub-process
            done


        done
    done < $CONFIGURATIONS_FILE
done < $INPUT



#After finishing tasks, wait for tools to finish their task.
    while (( $(pgrep -l java | wc -l) > 0 ))
    do
      activeProcesses=$(pgrep -l java | wc -l)
      echo "There are still $activeProcesses active java processes: "
      pgrep -l java
      sleep 5
    done