package org.evosuite.ga.metaheuristics.mosa.utility;

import org.evosuite.Properties;
import org.evosuite.ga.FitnessFunction;
import org.evosuite.utils.LoggingUtils;

import java.util.HashMap;
import java.util.Map;

public class ObjectiveAgeUtility {
    private static ObjectiveAgeUtility instance = null;

    private Map<FitnessFunction,Long> coveredObjectivesAge;


    private ObjectiveAgeUtility(){
        coveredObjectivesAge = new HashMap<>();
    }


    public static ObjectiveAgeUtility getInstance(){
        if(instance == null){
            instance = new ObjectiveAgeUtility();
        }

        return instance;
    }


    public boolean alreadyfinished(FitnessFunction objective){
        return coveredObjectivesAge.containsKey(objective);
    }

    public void addNewCoveredObjective(FitnessFunction objective){
        if (alreadyfinished(objective)){
            throw new IllegalStateException("Objective is already finished");
        }

        coveredObjectivesAge.put(objective,objective.getAge());
    }

    public void writeCoveredObjectives() {
        for (FitnessFunction obj : coveredObjectivesAge.keySet()){
            LoggingUtils.getEvoLogger().info("Covered objective: "+obj.toString()+", "+coveredObjectivesAge.get(obj));
        }
        LoggingUtils.getEvoLogger().info("------------------------------");
    }
}
