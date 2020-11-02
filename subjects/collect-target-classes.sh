# ! We should run this script after collect-bug
# Output is two csv files: (i) target classes (for evosuite run) and (ii) relations between classes and bugs.

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
        echo "${clazz//[$'\t\r\n']},$pid,$bid" >> subjects/subjects.csv
    done
    # IFS=$'\n' read -rd '' -a classes <<< "$(defects4j query -p $pid -q "classes.modified")"
    # for cz in "${classes[@]}"
    # do
    #     echo ">>>>"$cz
    # done
done < subjects/bugs.csv