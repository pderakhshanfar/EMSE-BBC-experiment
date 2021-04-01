# EMSE-BBC-experiment

# Subject selection
__!__ Requirements: Defects4j

### Collect selected bugs:

```
bash subjects/collect-bugs.sh 
```

This script generates `bugs.csv` that contains project_id, bug_id, date fixed, and modified classes of selected bugs.

### Collect subjects

```
bash subjects/collect-target-classes.sh 
```

This script generates `subjects.csv` in which all of the class under tests are indicated. This csv file will be used for the test generation process.

### Collect and compile buggy versions
```
bash subjects/collect-and-compile-buggy-versions.sh
```
This script store and complie all of the buggy versions required for this experimen in `subjects/buggy-versions`.


# Test Generation
## Docker container
For running the test generation tools:

First, you need to build the docker image:

```bash
. scripts/docker/build-test-generation-image.sh docker
```

Then, you need to run the docker container:
```bash
. scripts/docker/run-test-generation-container.sh docker
```
## Main test generation
For running the test generation you need to use the following command:
```
docker exec -it test-generation-container bash -c ". scripts/main/test-generation.sh <number-of-parallel-processes> <first-round> <last-round> <time-budget> <memory-used-by-each-evosuite-instance> <list-of-configurations> <list-of-subjects> [<seeds-dicrectory>]
```
## Replicating the test generation
All of the seeds used for our eperiment is already saved in `results/SEED`. For replicating our experiment, you need to pass this address to the main test generation script:

```
docker exec -it test-generation-container bash -c ". scripts/main/test-generation.sh 30 1 30 600 3000 configurations/configurations.csv subjects/subjects.csv results/SEED/
```

## Running the experiment with new seeds
For running the experiment with new seeds, just run the script without passing the seeds directory.
```
docker exec -it test-generation-container bash -c ". scripts/main/test-generation.sh 30 1 30 600 3000 configurations/configurations.csv subjects/subjects.csv
```

## Output
After running the experiment, the results of the test generations are all saved in `results` directory.
Currently, this directory contains the results achieved during our experiment.

## Collecting all results in a CSV file
For collecting the whole results in the csv file, run the following script:
```
. scripts/csv/generate_final_csv.sh 1 30 configurations/configurations.csv subjects/subjects.csv
```
Thw csv will be saved at `results/results.csv`.

# Captured failures
## Bug exposing stacktraces
__!__ All of the bug exposing stack traces are already saved in the root directory of buggy versions in `subjects/buggy-versions/<bug-name>`. However, to generate them again, you can run the following script:
```
. scripts/faults/generate_stack_traces.sh subjects/subjects.csv
```
## Remove try/catches
For making sure that the infrustracture can collect all of the captured exceptions, first, we need to run the following script to remove all of the try catches from the generated test suites:
```
python scripts/faults/remove-try-catches.py 
```

## Analyze captured exceptions
Finally, to collect the fault coverages, simply run the following script:
```
python scripts/faults/analyze-stacktraces.py 
```

The csv file reporting the fault coverages will be saved as `data/captured_exceptions.csv`. Currently, this file contains the results that we have collected from our main experiment.


# Data analysis
__@Xavier:__ Please complete this part.