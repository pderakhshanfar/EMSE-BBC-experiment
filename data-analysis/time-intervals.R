source('dataclean.r')
source('friedmantest.r')
raw_df <- getResultsWithInterval()

filtered_df <- raw_df %>%
  select(project,bug_id,configuration,execution_idx,TARGET_CLASS,
         BranchCoverage,Implicit_MethodExceptions,
         LineCoverageTimeline_T6,LineCoverageTimeline_T12,LineCoverageTimeline_T18,LineCoverageTimeline_T24,LineCoverageTimeline_T30,LineCoverageTimeline_T36,LineCoverageTimeline_T42,LineCoverageTimeline_T48,LineCoverageTimeline_T54,LineCoverageTimeline_T60,
         BranchCoverageTimeline_T6,BranchCoverageTimeline_T12,BranchCoverageTimeline_T18,BranchCoverageTimeline_T24,BranchCoverageTimeline_T30,BranchCoverageTimeline_T36,BranchCoverageTimeline_T42,BranchCoverageTimeline_T48,BranchCoverageTimeline_T54,BranchCoverageTimeline_T60,
         OutputCoverageTimeline_T6,OutputCoverageTimeline_T12,OutputCoverageTimeline_T18,OutputCoverageTimeline_T24,OutputCoverageTimeline_T30,OutputCoverageTimeline_T36,OutputCoverageTimeline_T42,OutputCoverageTimeline_T48,OutputCoverageTimeline_T54,OutputCoverageTimeline_T60,
         WeakMutationCoverageTimeline_T6,WeakMutationCoverageTimeline_T12,WeakMutationCoverageTimeline_T18,WeakMutationCoverageTimeline_T24,WeakMutationCoverageTimeline_T30,WeakMutationCoverageTimeline_T36,WeakMutationCoverageTimeline_T42,WeakMutationCoverageTimeline_T48,WeakMutationCoverageTimeline_T54,WeakMutationCoverageTimeline_T60,
         ExceptionCoverageTimeline_T6,ExceptionCoverageTimeline_T12,ExceptionCoverageTimeline_T18,ExceptionCoverageTimeline_T24,ExceptionCoverageTimeline_T30,ExceptionCoverageTimeline_T36,ExceptionCoverageTimeline_T42,ExceptionCoverageTimeline_T48,ExceptionCoverageTimeline_T54,ExceptionCoverageTimeline_T60) %>%
         mutate(case = paste0(as.character(project), '-', bug_id)) %>%
         group_by( case, configuration,TARGET_CLASS) %>%
         summarise(across(BranchCoverage:ExceptionCoverageTimeline_T60, mean)) %>%
         mutate(case = paste0(case, '-', TARGET_CLASS)) %>%
         as.data.frame()

filtered_df$case<-factor(filtered_df$case)
metrics <- c("BranchCoverageTimeline","OutputCoverageTimeline","WeakMutationCoverageTimeline","ExceptionCoverageTimeline")
for (metric in metrics){
  for(pointer in 1:10) {
    index = 6 * pointer
    c_name = paste0(metric, "_T", index)
    print(c_name)
    
    current_col <- filtered_df[,c_name]
    apply_conover(as.numeric(unlist(current_col)), 
                  filtered_df$configuration, 
                  filtered_df$case)
    rank <- apply_friedman_test(as.numeric(unlist(current_col)), 
                        filtered_df$configuration, 
                        filtered_df$case)
    pdf_name = paste0("output/trial/",c_name,".pdf")
    pdf(pdf_name, width=7, height=4) 
    if(metric == "ExceptionCoverageTimeline"){
      filtered_df %>%
        select(case, configuration, print(c_name)) %>%
        pivot_wider(names_from = configuration, values_from = !!c_name) %>%
        select(-case) %>%
        as.matrix() %>%
        nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
    }else{
      filtered_df %>%
        select(case, configuration, print(c_name)) %>%
        mutate(!!c_name := 1- current_col) %>%
        pivot_wider(names_from = configuration, values_from = !!c_name) %>%
        select(-case) %>%
        as.matrix() %>%
        nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
    }
    dev.off()
  }
}


#

filtered_df <- raw_df %>%
  select(project,bug_id,configuration,execution_idx,TARGET_CLASS,
         BranchCoverage) %>%
  mutate(case = paste0(as.character(project), '-', bug_id, '-',TARGET_CLASS))
meanBranchCoverage <- filtered_df %>%
  group_by( case, configuration) %>%
  summarise(mean_branch_coverage = mean(BranchCoverage),
            sd_branch_coverage = sd(BranchCoverage)) %>%
  as.data.frame()

apply_conover(meanBranchCoverage$mean_branch_coverage, 
              meanBranchCoverage$configuration, 
              meanBranchCoverage$case)

apply_friedman_test(meanBranchCoverage$mean_branch_coverage, 
                    meanBranchCoverage$configuration, 
                    meanBranchCoverage$case)

pdf("output/trial/branch-friedman-nemenyi.pdf", width=7, height=4) 
meanBranchCoverage %>%
  select(case, configuration, mean_branch_coverage) %>%
  mutate(mean_branch_coverage = 1 - mean_branch_coverage) %>% #The lowest is the best in our case
  pivot_wider(names_from = configuration, values_from = mean_branch_coverage) %>%
  select(-case) %>%
  as.matrix() %>%
  nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
dev.off()

