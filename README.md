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

