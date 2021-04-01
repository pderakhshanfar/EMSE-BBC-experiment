INPUT=$1

# Check input CSV file
[ ! -f $INPUT ] && { die "$INPUT file not found"; }


OLDIFS=$IFS
IFS=,

class_counter=0
root_dir=$(pwd)

while read project_id bug_id date_fixed modified_classes
do
    # skip the title row
    if [[ "$class_counter" -eq "0" ]]; then
        class_counter="$(( class_counter + 1 ))"
        continue
    fi

    project_name=$project_id-$bug_id
    project_dir="$root_dir/subjects/buggy-versions/$project_name/"

    echo "Going to $project_dir"
    cd $project_dir
    
    
    # First, export List of test methods that trigger (expose) the bug
    defects4j export -p tests.trigger > "trig-test.txt"
    echo "" >> trig-test.txt
    
    rm stackTraces.txt
    
    #Then, we execute the exported tests
    cat trig-test.txt | while read testcase; do
        echo "Running $testcase ..."
        defects4j test -t "$testcase"
        cat failing_tests >> stackTraces.txt
        echo "------------------" >> stackTraces.txt
    done


done < $INPUT

cd $root_dir
IFS=$OLDIFS