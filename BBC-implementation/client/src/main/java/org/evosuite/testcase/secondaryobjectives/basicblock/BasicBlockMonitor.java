package org.evosuite.testcase.secondaryobjectives.basicblock;

import org.evosuite.ga.FitnessFunction;
import org.evosuite.testcase.TestFitnessFunction;
import org.evosuite.utils.LoggingUtils;

import java.util.HashMap;
import java.util.Map;

public class BasicBlockMonitor {

    private static BasicBlockMonitor instance;
    private Map<FitnessFunction,Integer> calledForObjective = new HashMap<>();
    private Map<FitnessFunction,Integer> BBCActivates = new HashMap<>();
    private Map<FitnessFunction,Integer> BBCSelectsAWinner = new HashMap<>();
    private Map<FitnessFunction,Integer> objectiveFFEval = new HashMap<>();


    private BasicBlockMonitor(){

    }


    public static BasicBlockMonitor getInstance(){
        if (instance == null){
            instance = new BasicBlockMonitor();
        }

        return instance;
    }


    public void newTrigger(FitnessFunction objective){
        int count = calledForObjective.containsKey(objective) ? calledForObjective.get(objective) : 0;
        calledForObjective.put(objective,count + 1);
    }

    public void newFFEval(TestFitnessFunction objective) {
        int count = objectiveFFEval.containsKey(objective) ? objectiveFFEval.get(objective) : 0;
        objectiveFFEval.put(objective,count + 1);
    }

    public void newWinnerSelection(FitnessFunction objective) {
        int count = BBCSelectsAWinner.containsKey(objective) ? BBCSelectsAWinner.get(objective) : 0;
        BBCSelectsAWinner.put(objective,count + 1);
    }

    public void newActivation(FitnessFunction objective) {
        int count = BBCActivates.containsKey(objective) ? BBCActivates.get(objective) : 0;
        BBCActivates.put(objective,count + 1);
    }

    public void report(){
        int total = 0;
        for (FitnessFunction objective : calledForObjective.keySet()){
                    int activateCount = BBCActivates.containsKey(objective) ? BBCActivates.get(objective) : 0;
                    int selectsWinner = BBCSelectsAWinner.containsKey(objective) ? BBCSelectsAWinner.get(objective) : 0;
            		LoggingUtils.getEvoLogger().info("Number of times BBC is called, activated, and useful for "+objective.toString()+": "+calledForObjective.get(objective)+","+activateCount+","+selectsWinner+"| Number of FF evals: "+objectiveFFEval.get(objective));
//            		total += calledForObjective.get(objective);
        }
//        LoggingUtils.getEvoLogger().info("Number of times BBC is called in total: "+ total);
    }


}
