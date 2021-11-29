package org.evosuite.systemtest;

import com.examples.with.different.packagename.implicitbranch.ExternalImplicitException;
import org.evosuite.EvoSuite;
import org.evosuite.Properties;
import org.junit.Test;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

public class SystemTest {

    @Test
    public void simpleTest(){
//        Properties.SECONDARY_OBJECTIVE = new Properties.SecondaryObjective[] {Properties.SecondaryObjective.BasicBlockCoverage};
        EvoSuite evosuite = new EvoSuite();

//        String targetClass = "org.jfree.chart.plot.CategoryPlot";
//        String targetClass = "org.jfree.chart.plot.XYPlot";
//        String targetClass = "org.jsoup.parser.HtmlTreeBuilderState";
//        String targetClass = "com.fasterxml.jackson.databind.node.TreeTraversingParser";
        String targetClass = "com.fasterxml.jackson.databind.ser.DefaultSerializerProvider";
//        String targetClass = ExternalImplicitException.class.getCanonicalName();
        Properties.TARGET_CLASS = targetClass;
        String user_dir = System.getProperty("user.dir");
        System.out.println(user_dir);
        File file = new File(user_dir);

        Path experiment_path = Paths.get(file.getParent(), "..","EMSE-BBC-experiment","subjects","buggy-versions");
        String experiment_path_string = experiment_path.toFile().getAbsolutePath();
        Path framework_path = Paths.get(file.getParent(), "..","EMSE-BBC-experiment","defects4j","framework");
        String framework_path_string = framework_path.toFile().getAbsolutePath();



        System.out.println(experiment_path_string);
//        String projectCP = experiment_path_string+"/Jsoup-87/target/classes";
//        String projectCP = experiment_path_string+"/Chart-4/build:"+experiment_path_string+"/Chart-4/lib/servlet.jar";
        String projectCP = experiment_path_string+"/JacksonDatabind-103/target/classes:"+framework_path_string+"/projects/JacksonDatabind/lib/com/fasterxml/jackson/core/jackson-annotations/2.9.0/jackson-annotations-2.9.0.jar:"+framework_path_string+"/projects/JacksonDatabind/lib/com/fasterxml/jackson/core/jackson-core/2.9.7/jackson-core-2.9.7.jar";
        System.out.println(projectCP);
//
        String[] command = new String[] { "-class", targetClass ,
                "-projectCP", projectCP,
                "-Dsearch_budget=60",
                "-Dsecondary_objectives="+Properties.SecondaryObjective.BBCOVERAGE.name()+":"+Properties.SecondaryObjective.TOTAL_LENGTH,
                "-Doutput_variables=TARGET_CLASS,search_budget,Total_Time,Length,Size,LineCoverage,BranchCoverage,OutputCoverage,WeakMutationScore,Implicit_MethodExceptions,MutationScore",
                "-seed", "218328285",
//                "-mem", "3000",
                "-DBBC_USAGE_PERCENTAGE="+100,
//                "-Dpopulation="+10,
//                "-Dtt_scope=TARGET",
                "-Dsandbox=FALSE",
//                "-DTT=TRUE",
                "-Dreport_dir="+"/Users/pooria/IdeaProjects/evosuite/master/src/test/java/org/evosuite/systemtest"
        };
//
        Object result = evosuite.parseCommandLine(command);
    }
}
