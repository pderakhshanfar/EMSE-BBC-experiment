round=$1
configuration_name=$2
project_name=$3
project_cp=$4
target_class=$5
Budget=$6
Mem=$7
SEED=$8
user_configuration_array=$9

# Check if SEED exists
if [[ "$SEED" = "0" ]]; then
    # Generate SEED
    seed_value="$(od -vAn -N4 -t u4 < /dev/urandom | tr -d ' ')"
else
    # Parse SEED
    if [ -f "$SEED/$project_name/$target_class/$configuration_name/$round/seed" ]; then
        seed_value=$(cat $SEED/$project_name/$target_class/$configuration_name/$round/seed)
    else
     echo "ERROR! SEED $SEED/$project_name/$target_class/$configuration_name/$round/seed does not exist"
     return
    fi   
fi
echo "SEED value: $seed_value"

# Prepare SEED output directory
if [ ! -d "results/SEED/$project_name/$target_class/$configuration_name/$round" ]; then
    mkdir -p "results/SEED/$project_name/$target_class/$configuration_name/$round"
fi
# Write seed value
echo -n $seed_value > "results/SEED/$project_name/$target_class/$configuration_name/$round/seed"

# Prepare variables for output directories
report_dir="results/$project_name/$target_class/$configuration_name/reports/$round"
test_dir="results/$project_name/$target_class/$configuration_name/tests/$round"
log_file="logs/$project_name-$target_class-$configuration_name-$round"

# "results/$project_name/$target_class/$configuration_name/logs/$round"

TIMEOUT="$(( Budget * 2 ))"

mkdir -p "results/$project_name/$target_class/$configuration_name/logs/"
echo "${user_configuration_array[@]}"

# Run EvoSuite
timeout -k $TIMEOUT $TIMEOUT /usr/bin/env java -Xmx4G -jar tools/evosuite.jar \
-mem "${Mem}" \
-Dconfiguration_id="${configuration_name}" \
-Dgroup_id="${project_name}" \
-projectCP "${project_cp}" \
-class "${target_class}" \
-seed "${seed_value}" \
-Dreport_dir="${report_dir}" \
-Dtest_dir="${test_dir}" \
-Dshow_progress='false' \
-Dplot='false' \
-Dtimeline_interval=10000 \
-Dsandbox=FALSE \
-Dsearch_budget="${Budget}" \
-Doutput_variables=TARGET_CLASS,search_budget,Total_Time,Length,Size,LineCoverage,BranchCoverage,OutputCoverage,WeakMutationScore,Implicit_MethodExceptions,CoverageTimeline,LineCoverageTimeline,BranchCoverageTimeline,OutputCoverageTimeline,WeakMutationCoverageTimeline,ExceptionCoverageTimeline \
"${user_configuration_array[@]}" &
sleep 1
# pid=$!
# wait $pid

# echo "Process is finished. Checking $report_dir"


# # Check if report is available
# if [ -f "$report_dir/statistics.csv" ]; then
#     echo "Report is saved at $report_dir"
# else
#     echo "Report is not available at $report_dir. Will rerun the process."
#     {
#         flock -x 3                       # grab a lock on file descriptor #3
#         new_row="$project_name, $target_class, $configuration_name, ${user_configuration_array[@]}" 
#         echo "@> $new_row"
#         printf "$new_row" >&3   # Write new content to the FD
#     } 3>>text.txt                      
#     # . scripts/run/run_evosuite.sh $round $configuration_name $project_name $project_cp $target_class $budget $Mem $SEED $user_configuration_array &
# fi

# Run observer
# . scripts/run/evosuite-observer.sh $pid $log_file $report_dir $test_dir $Budget $round $configuration_name $project_name $project_cp $target_class $Mem $SEED $user_configuration_array &
