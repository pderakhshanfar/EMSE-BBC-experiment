

for d in $(ls -d buggy-versions/*);do
  (./bin/javancss-33.54/bin/javancss -recursive -all -out $d/ccn.txt $d)
done;

python3 python/stats.py subjects.csv stats.csv
