
OLDIFS=$IFS
IFS=,

CONFIGURATIONS_FILE=$1
INPUT=$2

# Check input CSV file
[ ! -f $INPUT ] && { die "$INPUT file not found"; }

class_counter=0
while read target_class project bug_id
do
    # skip the title row
    if [[ "$class_counter" -eq "0" ]]; then
        class_counter="$(( class_counter + 1 ))"
        continue
    fi

    project_name=$project-$bug_id

    configuration_header_passed=0
    while read configuration_name args
    do
        # skip the title row
        if [[ "$configuration_header_passed" -eq "0" ]]; then
            configuration_header_passed="1"
            continue
        fi

        results_dir="results/$project_name/$target_class/$configuration_name"


        rm -r "$results_dir"




    done < $CONFIGURATIONS_FILE


done < $INPUT


IFS=$OLDIFS
