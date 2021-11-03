source('dataclean.r')
source('friedmantest.r')
library(ggplot2)
library(effsize)

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
         as.data.frame() %>%
         filter(configuration %in% c("BBC-F0-opt-50","default"))




metrics <- c("BranchCoverageTimeline","OutputCoverageTimeline","WeakMutationCoverageTimeline","ExceptionCoverageTimeline")


pairwise_df <- raw_df %>%
  filter(configuration %in% c("BBC-F0-opt-50") ) %>%
  inner_join(
    raw_df %>%
      filter(configuration == "default"),
    by = c('project', 'bug_id', 'TARGET_CLASS'),
    suffix = c('.config', '.base'))

reformatted_df <- data.frame(case=character(), 
                             configuration=character(), 
                             type=character(),
                             value=numeric(),
                             stringsAsFactors=FALSE) 
for (metric in metrics){
  for(pointer in 1:10) {
    if((pointer %% 2) == 0) {
      index = 6 * pointer
      type = paste0(metric, "_T", index)
      for (row in 1:nrow(filtered_df)) {
        case <- filtered_df[row, "case"]
        configuration  <- as.character(filtered_df[row, "configuration"])
        value <- as.numeric(filtered_df[row, type])
        reformatted_df[nrow(reformatted_df) + 1,] = c(case,configuration,type,value)
      }
    }
  }
}


# Branch Coverage
BranchCoverage_interval_df <- reformatted_df %>%
  filter(startsWith(type,"BranchCoverageTimeline"))

BranchCoverage_interval_df$type <- factor(BranchCoverage_interval_df$type,
                                          levels=c("BranchCoverageTimeline_T6","BranchCoverageTimeline_T12","BranchCoverageTimeline_T18","BranchCoverageTimeline_T24","BranchCoverageTimeline_T30","BranchCoverageTimeline_T36","BranchCoverageTimeline_T42","BranchCoverageTimeline_T48","BranchCoverageTimeline_T54","BranchCoverageTimeline_T60"),
                                          labels=c("1min","2min","3min","4min","5min","6min","7min","8min","9min","10min"))

pdf_name <- paste0("output/intervals/BranchCoverageInterval.pdf")
BranchCoverage_interval_df %>%
  ggplot(aes(x = as.factor(configuration), y = as.double(value))) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  facet_wrap(.~type, ncol = 5) +
  labs(y= "Branch Coverage", x = "Configuration")
ggsave(pdf_name, width = 7, height = 3)
facet_grid(vars(type),vars(configuration), margins= "project", scales = "free_x")


# Output Coverage
OutputCoverage_interval_df <- reformatted_df %>%
  filter(startsWith(type,"OutputCoverageTimeline"))


OutputCoverage_interval_df$type <- factor(OutputCoverage_interval_df$type,
                                          levels=c("OutputCoverageTimeline_T6","OutputCoverageTimeline_T12","OutputCoverageTimeline_T18","OutputCoverageTimeline_T24","OutputCoverageTimeline_T30","OutputCoverageTimeline_T36","OutputCoverageTimeline_T42","OutputCoverageTimeline_T48","OutputCoverageTimeline_T54","OutputCoverageTimeline_T60"),
                                          labels=c("1min","2min","3min","4min","5min","6min","7min","8min","9min","10min"))

pdf_name <- paste0("output/intervals/OutputCoverageInterval.pdf")
OutputCoverage_interval_df %>%
  ggplot(aes(x = as.factor(configuration), y = as.double(value))) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  facet_wrap(.~type, ncol = 5) +
  labs(y= "Output Coverage", x = "Configuration")
ggsave(pdf_name, width = 7, height = 3)
facet_grid(vars(type),vars(configuration), margins= "project", scales = "free_x")


# Exception Coverage (This fitness function considers both implicit and explicit exception)
ExceptionCoverage_interval_df <- reformatted_df %>%
  filter(startsWith(type,"ExceptionCoverageTimeline"))

ExceptionCoverage_interval_df$type <- factor(ExceptionCoverage_interval_df$type,
                                          levels=c("ExceptionCoverageTimeline_T6","ExceptionCoverageTimeline_T12","ExceptionCoverageTimeline_T18","ExceptionCoverageTimeline_T24","ExceptionCoverageTimeline_T30","ExceptionCoverageTimeline_T36","ExceptionCoverageTimeline_T42","ExceptionCoverageTimeline_T48","ExceptionCoverageTimeline_T54","ExceptionCoverageTimeline_T60"),
                                          labels=c("1min","2min","3min","4min","5min","6min","7min","8min","9min","10min"))



pdf_name <- paste0("output/intervals/ExceptionCoverageInterval.pdf")
ExceptionCoverage_interval_df %>%
  ggplot(aes(x = as.factor(configuration), y = as.double(value))) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  facet_wrap(.~type, ncol = 5) +
  labs(y= "Exception Coverage", x = "Configuration")
ggsave(pdf_name, width = 7, height = 3)
facet_grid(vars(type),vars(configuration), margins= "project", scales = "free_x")

# Weak Mutation Score
WeakMutationCoverage_interval_df <- reformatted_df %>%
  filter(startsWith(type,"WeakMutationCoverageTimeline"))


WeakMutationCoverage_interval_df$type <- factor(WeakMutationCoverage_interval_df$type,
                                             levels=c("WeakMutationCoverageTimeline_T6","WeakMutationCoverageTimeline_T12","WeakMutationCoverageTimeline_T18","WeakMutationCoverageTimeline_T24","WeakMutationCoverageTimeline_T30","WeakMutationCoverageTimeline_T36","WeakMutationCoverageTimeline_T42","WeakMutationCoverageTimeline_T48","WeakMutationCoverageTimeline_T54","WeakMutationCoverageTimeline_T60"),
                                             labels=c("1min","2min","3min","4min","5min","6min","7min","8min","9min","10min"))


pdf_name <- paste0("output/intervals/WeakMutationCoverageInterval.pdf")
WeakMutationCoverage_interval_df %>%
  ggplot(aes(x = as.factor(configuration), y = as.double(value))) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  facet_wrap(.~type, ncol = 5) +
  labs(y= "Weak mutation score", x = "Configuration")
ggsave(pdf_name, width = 7, height = 3)
facet_grid(vars(type),vars(configuration), margins= "project", scales = "free_x")


# This loop genrate plots related to friedman test and vargha delaney effect sizes
for (metric in metrics){
  for(pointer in 1:10) {
    if((pointer %% 2) == 1) {
      next
    }
    index = 6 * pointer
    c_name = paste0(metric, "_T", index)
    print(c_name)
    
    current_col <- filtered_df[,c_name]
    
    
    ##  Analysis using Friedman's test
    apply_conover(as.numeric(unlist(current_col)), 
                  filtered_df$configuration, 
                  filtered_df$case)
    rank <- apply_friedman_test(as.numeric(unlist(current_col)), 
                        filtered_df$configuration, 
                        filtered_df$case)
    pdf_name = paste0("output/intervals/friedman/friedman_",c_name,".pdf")
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
    
    
    # ## Overall distribution
    # pdf_name = paste0("output/trial/overall_",c_name,".pdf")
    # current_col <- raw_df[,c_name]
    # 
    # if(metric == "ExceptionCoverageTimeline"){
    #   current_col <- 1- current_col
    # }
    # raw_df %>%
    # ggplot(aes(x = configuration, y =  current_col)) +
    #   geom_boxplot() +
    #   stat_summary(
    #     fun = mean,
    #     geom = "point",
    #     shape = 0,
    #     color = "black",
    #     fill = "white"
    #   ) +
    #   xlab(NULL) +
    #   ylab(c_name) +
    #   theme(axis.text.x = element_text(angle = 55, vjust = 0.5))
    # ggsave(pdf_name, width = 4.5, height = 3)
    
    
    ## Pairwise comparison
    pdf_name = paste0("output/intervals/pairwise/pairwise_",c_name,".pdf")
    config_c <- paste0(c_name,".config")
    config_b <- paste0(c_name,".base")
    pairwise <- pairwise_df %>%
      group_by(project, bug_id, TARGET_CLASS, configuration.config) %>%
      summarise(
         coverage.VD.magnitude = VD.A(!!as.name(config_c), !!as.name(config_b))$magnitude,
         coverage.VD.estimate = VD.A(!!as.name(config_c), !!as.name(config_b))$estimate,
         coverage.wilcox.test.pvalue = wilcox.test(!!as.name(config_c), !!as.name(config_b))$p.value,
         mean.config = mean(!!as.name(config_c)),
         mean.base = mean(!!as.name(config_b))
      ) %>%
      filter(coverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
    mutate(coverage.VD.estimate.category = case_when(
      coverage.VD.estimate < 0.5 ~ '< 0.5',
      coverage.VD.estimate > 0.5 ~ '> 0.5',
      TRUE ~ '= 0.5'))
    
    
    pairwise %>%
      group_by(coverage.VD.estimate.category) %>%
      summarise(count = n()) %>%
      ggplot(aes(x=coverage.VD.estimate.category, y=count)) +
      geom_bar(stat="identity", fill="steelblue")+
      geom_text(aes(label=count), vjust=1.6, color="white", size=3.5)+
      theme_minimal()
    ggsave(pdf_name, width = 4.5, height = 3.5)
    
    pdf_name = paste0("output/intervals/effectsize/VD_",c_name,".pdf")
    pairwise %>%
      ggplot(aes(x = configuration.config, y = coverage.VD.estimate)) +
      geom_boxplot() +
      stat_summary(
        fun.data = function(x){stat_box_data(x, upper_limit = 1.15)}, 
        geom = "text", 
        hjust = 0.5,
        vjust = 0.9
      ) +
      stat_summary(
        fun = mean,
        geom = "point",
        shape = 0,
        color = "black",
        fill = "white"
      ) +
      geom_hline(yintercept = 0.5, linetype=2, color="blue") +
      xlab(NULL) +
      theme(axis.text.x = element_text(angle = 55, vjust = 0.5)) +
      ylab('VD') +
      scale_y_continuous(limits = c (0.0, 1.2), breaks = c(0.25, 0.5, 0.75, 1.0))
    ggsave(pdf_name, width = 4.5, height = 3.5)
  }
}



