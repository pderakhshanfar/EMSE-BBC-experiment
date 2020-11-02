# ! We should run this script after collect-bug
# Output is the list of target classes for evosuite run.

echo "target_class,project_id,bug_id" > subjects/subjects.csv

# Start an iteration on the collected bugs
counter=0
IFS=,
while read pid bid date_fixed modified_classes
do
    # skip the title row
    if [[ "$counter" -eq "0" ]]; then
        counter=1
        continue
    fi

    echo "PID: $pid, BID: $bid, date: $date_fixed, modified classes: $modified_classes"
    IFS=$';' read -rd '' -a classes <<< "$modified_classes"
    for clazz in "${classes[@]}"
    do
        CLEANED=${clazz//[$'\t\r\n']}
        if [[ "$CLEANED" == *.txt ]]
        then
            continue
        else
            echo "$CLEANED,$pid,$bid" >> subjects/subjects.csv
        fi
    done
done < subjects/bugs.csv