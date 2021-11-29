package org.evosuite.testcase.secondaryobjectives.basicblock;

import org.evosuite.Properties;

import org.evosuite.TestGenerationContext;
import org.evosuite.ga.FitnessFunction;
import org.evosuite.ga.SecondaryObjective;
import org.evosuite.graphs.cfg.ActualControlFlowGraph;
import org.evosuite.graphs.cfg.BasicBlock;
import org.evosuite.graphs.cfg.BytecodeInstructionPool;
import org.evosuite.testcase.TestChromosome;
import org.evosuite.utils.Randomness;

import java.util.List;
import java.util.Set;


public class BasicBlockCoverage extends SecondaryObjective<TestChromosome> {

    BasicBlockUtility basicBlockUtility;
    private final Randomness random =Randomness.getInstance();

    public BasicBlockCoverage(){
        super();
        basicBlockUtility = new BasicBlockUtility();
    }

    public int compareChromosomes(TestChromosome chromosome1, TestChromosome chromosome2, FitnessFunction objective){
        // Check the BBC usage probability
        int random_int =random.nextInt(100);
        if (random_int >=  Properties.BBC_USAGE_PERCENTAGE) {
            return 0;
        }

        // Check the objective. BBC can be helpful for line and branch coverage, which are utilizing approach level and branch distance.
        if(!basicBlockUtility.isBBCApplicable(objective)){
            return 0;
        }
//        BasicBlockMonitor.getInstance().newTrigger(objective);


        // Check sleep time.
        if (objective.getAge() <= (Properties.BBC_SLEEP_TIME)){
            return 0;
        }

        // Return 0 if both executions do not throw any exception
        if (! chromosome1.hasException() && ! chromosome2.hasException()){
            return 0;
        }


        // Get target class, method, and line.
        String targetClass = Properties.TARGET_CLASS;
        String targetMethod = basicBlockUtility.getTargetMethod(objective);
        int targetLine = basicBlockUtility.getTargetLineNumber(objective);

        // Get target method control flow graph and target block
        if(BytecodeInstructionPool.getInstance(TestGenerationContext.getInstance().getClassLoaderForSUT()).getFirstInstructionAtLineNumber(targetClass,targetMethod,targetLine) == null){
            return 0;
        }
        ActualControlFlowGraph targetMethodCFG = BytecodeInstructionPool.getInstance(TestGenerationContext.getInstance().getClassLoaderForSUT()).getFirstInstructionAtLineNumber(targetClass,targetMethod,targetLine).getActualCFG();
        BasicBlock targetBlock = BytecodeInstructionPool.getInstance(TestGenerationContext.getInstance().getClassLoaderForSUT()).getFirstInstructionAtLineNumber(targetClass,targetMethod,targetLine).getBasicBlock();

        // Collect lines in target method which are covered by each of the given chromosomes.
        Set<Integer> coveredLines1 = basicBlockUtility.getCoveredLines(chromosome1, targetMethodCFG);
        Set<Integer> coveredLines2 = basicBlockUtility.getCoveredLines(chromosome2, targetMethodCFG);


        // Chromosome 1 and 2 covered the target line and the only remaining thing is covering the right branch. In this case, BBC cannot help.
        if(coveredLines1.contains(targetLine) && coveredLines2.contains(targetLine)){
            return 0;
        }

        // If covered lines are identical, we dont need to check the coverage.
        if(coveredLines1.equals(coveredLines2)){
            return 0;
        }

        int finalValue=0;
//        BasicBlockMonitor.getInstance().newActivation(objective);

        // Detect last covered control dependent node in the given chromosomes. This node is the same as we have same approach level and branch distance.
        BasicBlock closestCoveredControlDependency = basicBlockUtility.getClosestCoveredControlDependency(targetBlock, coveredLines1);


        // Calcualte the covered blocks for both chromosomes
        List<Set<BasicBlock>> coveredBasicBlocks1 = basicBlockUtility.collectCoveredBasicBlocks(targetMethodCFG,targetLine,targetBlock,coveredLines1,closestCoveredControlDependency);
        List<Set<BasicBlock>> coveredBasicBlocks2 = basicBlockUtility.collectCoveredBasicBlocks(targetMethodCFG,targetLine,targetBlock,coveredLines2,closestCoveredControlDependency);

        // Collect FCB1 and SCB1
        Set<BasicBlock> FCB1 = coveredBasicBlocks1.get(0);
        Set<BasicBlock> semiCovered1 = coveredBasicBlocks1.get(1);
        // SCB is the closest semi covered block to the target block.
        BasicBlock SCB1 = basicBlockUtility.findTheClosestBlock(semiCovered1,targetMethodCFG,targetBlock);

        // Collect FCB2 and SCB2
        Set<BasicBlock> FCB2 = coveredBasicBlocks2.get(0);
        Set<BasicBlock> semiCovered2 = coveredBasicBlocks2.get(1);
        BasicBlock SCB2 = basicBlockUtility.findTheClosestBlock(semiCovered2,targetMethodCFG,targetBlock);


        // Check if both chromosomes get stuck in a same basic block
        if(basicBlockUtility.goDeeper(FCB1,SCB1,FCB2,SCB2)){
            finalValue=basicBlockUtility.compareCoveredLines(chromosome1,chromosome2,SCB1,targetLine);
        // Otherwise, check heck if one of the chromosomes has more coverage in the effective basic blocks
        }else if (basicBlockUtility.oneChromosomeHasMoreCoveredBlocks(FCB1,SCB1,FCB2,SCB2)){

            // chromosome 2 coverage is a subset of chromosome 1 coverage
            // or
            // chromosome 1 coverage is a subset of chromosome 2 coverage
            // the returned value is >0 if chromosome1 is a subset of chromosome2 and vice versa.

            finalValue = basicBlockUtility.getCoverageSize(FCB2) - basicBlockUtility.getCoverageSize(FCB1);
        }else{
            // Here, we cannot say which test is better. So, we set the final value to zero.
            finalValue= 0;
        }
//        if(finalValue != 0){
//            BasicBlockMonitor.getInstance().newWinnerSelection(objective);
//        }
        // return the calculated final value
        return finalValue;
    }

    /*
    * This method is only called in places that BBC is irrelevant.
    * For instance, in archive, since archive is about the covered targets and we dont have any target to reach, we call this method to get 0 all of the times.
     * */
    @Override
    public int compareChromosomes(TestChromosome chromosome1, TestChromosome chromosome2) {
        return 0;
    }

    @Override
    public int compareGenerations(TestChromosome parent1, TestChromosome parent2,
                                  TestChromosome child1, TestChromosome child2) {
        return 0;
    }
}
