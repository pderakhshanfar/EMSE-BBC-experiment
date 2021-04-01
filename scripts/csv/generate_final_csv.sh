# Add new separator


FirstRound=$1
LastRound=$2

CONFIGURATIONS_FILE=$3
INPUT=$4


containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}


# Check input CSV file
[ ! -f $INPUT ] && { die "$INPUT file not found"; }

# Initialize the final CSV
final_csv="results/results.csv"
blacklist=()
# blacklist=("Closure-110/com.google.javascript.rhino.Node" "Codec-14/org.apache.commons.codec.language.bm.Lang" "Codec-14/org.apache.commons.codec.language.bm.Rule" "Codec-13/org.apache.commons.codec.binary.CharSequenceUtils" "Collections-28/org.apache.commons.collections4.trie.AbstractPatriciaTrie" "Compress-47/org.apache.commons.compress.archivers.zip.ZipArchiveInputStream" "Compress-42/org.apache.commons.compress.archivers.zip.UnixStat" "Compress-41/org.apache.commons.compress.archivers.zip.ZipArchiveInputStream" "Gson-12/com.google.gson.internal.bind.JsonTreeReader" "Gson-9/com.google.gson.internal.bind.JsonTreeWriter" "JacksonCore-26/com.fasterxml.jackson.core.json.async.NonBlockingJsonParser" "JacksonDatabind-103/com.fasterxml.jackson.databind.deser.std.StdKeyDeserializer")
# blacklist=("Closure-110/com.google.javascript.rhino.Node" "Collections-28/org.apache.commons.collections4.trie.AbstractPatriciaTrie" "Gson-12/com.google.gson.internal.bind.JsonTreeReader" "Gson-9/com.google.gson.internal.bind.JsonTreeWriter" "JacksonDatabind-103/com.fasterxml.jackson.databind.deser.std.StdKeyDeserializer" "Mockito-4/org.mockito.exceptions.Reporter" "Mockito-20/org.mockito.internal.creation.bytebuddy.ByteBuddyMockMaker" "Time-8/org.joda.time.DateTimeZone")
echo "project,bug_id,configuration,execution_idx,TARGET_CLASS,search_budget,Total_Time,Length,Size,LineCoverage,BranchCoverage,OutputCoverage,WeakMutationScore,Implicit_MethodExceptions" > $final_csv

OLDIFS=$IFS
IFS=,

completed=1
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
        for (( round=FirstRound; round<=LastRound; round++ ))
        do
            report_file="results/$project_name/$target_class/$configuration_name/reports/$round/statistics.csv"
            

            if [ ! -f "$report_file" ]; then
                temp="$project_name/$target_class"
                containsElement "$temp" "${blacklist[@]}"
                if [[ "$?" -eq "1" ]]; then
                  echo $report_file" Does not exist!"
                  completed=0
                fi
                continue
            fi

            IFS="|"
            row="$project,$bug_id,$configuration_name,$round,"$(sed -n '2p' $report_file)
            echo $row >> $final_csv
            IFS=,
        done
        
      done < $CONFIGURATIONS_FILE
       if [[ "$completed" -eq "0" ]]; then
        echo "BREAK"
        break
      fi
      
done < $INPUT


IFS=$OLDIFS