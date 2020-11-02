# This script collects all of the subjects for experiment using Defects4j v2.0


IFS=$'\n' read -rd '' -a pids <<<"$(defects4j pids)"


echo " Number of projects in Defects4j: ${#pids[@]}"
echo "Iterating on projects ..."

mkdir subjects/temp
echo "project_id,bug_id,date_fixed,modified_classes" > subjects/bugs.csv
for project_id in "${pids[@]}"
do
    # echo "$(defects4j bids -p $project_id)"
    IFS=$'\n' read -rd '' -a bids <<<"$(defects4j bids -p $project_id)"
    echo "Project id: $project_id - number of active bugs: ${#bids[@]}"

    defects4j query -p $project_id -q "revision.date.fixed,classes.modified" > "subjects/temp/$project_id.csv"

    python subjects/python/sort.py "subjects/temp/$project_id.csv"

    echo "10 most recently fixed bugs are selected"
done


rm -rf subjects/temp


