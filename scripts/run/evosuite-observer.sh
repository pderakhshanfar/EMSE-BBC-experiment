pid=$1
log_file=$2
report_dir=$3
test_dir=$4
budget=$5

round=$6
configuration_name=$7
project_name=$8
project_cp=$9
target_class=${10}
Mem=${11}
SEED=${12}
user_configuration_array=${13}
## Wait until either the process ends or the process stays inactive for 5 minutes
TIMEOUT="$(( budget * 2 ))"
echo ">>>>"$pid


# # timeout -t $TIMEOUT tail --pid=$pid -f /dev/null
# # timeout -t "${TIMEOUT}" wait $pid
# echo "Process is finished. Checking $report_dir"
# #Kill process
# kill "$pid"
# echo "killing process $pid"

# Check if report is available
if [ -f "$report_dir/statistics.csv" ]; then
    echo "Report is saved at $report_dir"
else
    echo "Report is not available at $report_dir. Rerun the process."
    . scripts/run/run_evosuite.sh $round $configuration_name $project_name $project_cp $target_class $budget $Mem $SEED $user_configuration_array &
fi
