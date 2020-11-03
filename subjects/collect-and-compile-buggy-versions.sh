# ! We should run this script after collect-bug

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

    dir="subjects/buggy-versions/$pid-$bid"
    mkdir $dir
    defects4j checkout -p $pid -v "$bid"b -w $dir
    defects4j compile -w $dir

    currentDir=$(pwd)
    echo "Entering $dir"
    cd $dir

    if [ -f "cp-entries.txt" ]; then
        echo "cp-entries.txt exists."
        cd $currentDir
        continue
    fi

    cp=$(defects4j export -p cp.compile)
    content=$(python ../../python/export-cp.py $cp)

    if [ $content == "0" ]; then 
        echo "!!! $cp"
        cd $currentDir
        break
    else
        echo -n $content > cp-entries.txt
    fi
    rm -rf .git/
    rm .gitignore

    cd $currentDir
done < subjects/bugs.csv