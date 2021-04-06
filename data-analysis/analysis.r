source('dataclean.r')
source('friedmantest.r')

library(ggplot2)
library(questionr)
library(effsize)

results <- getResults()

# Pairwise comparison between differenf cases and configuration
pairwise <- results %>%
  filter(configuration != 'DynaMOSA') %>%
  inner_join(
    results %>%
      filter(configuration == 'DynaMOSA'),
    by = c('project', 'bug_id', 'case', 'TARGET_CLASS'),
    suffix = c('.config', '.base')) %>%
  group_by(project, bug_id, case, TARGET_CLASS, configuration.config)  %>%
  summarise(BranchCoverage.VD.magnitude = VD.A(BranchCoverage.config, BranchCoverage.base)$magnitude,
            BranchCoverage.VD.estimate = VD.A(BranchCoverage.config, BranchCoverage.base)$estimate,
            BranchCoverage.wilcox.test.pvalue = wilcox.test(BranchCoverage.config, BranchCoverage.base)$p.value,
            WeakMutationScore.VD.magnitude = VD.A(WeakMutationScore.config, WeakMutationScore.base)$magnitude,
            WeakMutationScore.VD.estimate = VD.A(WeakMutationScore.config, WeakMutationScore.base)$estimate,
            WeakMutationScore.wilcox.test.pvalue = wilcox.test(WeakMutationScore.config, WeakMutationScore.base)$p.value,
            OutputCoverage.VD.magnitude = VD.A(OutputCoverage.config, OutputCoverage.base)$magnitude,
            OutputCoverage.VD.estimate = VD.A(OutputCoverage.config, OutputCoverage.base)$estimate,
            OutputCoverage.wilcox.test.pvalue = wilcox.test(OutputCoverage.config, OutputCoverage.base)$p.value) %>%
  mutate(BranchCoverage.VD.estimate.category = case_when(
    BranchCoverage.VD.estimate < 0.5 ~ '< 0.5',
    BranchCoverage.VD.estimate > 0.5 ~ '> 0.5',
    TRUE ~ '= 0.5'),
    WeakMutationScore.VD.estimate.category = case_when(
      WeakMutationScore.VD.estimate < 0.5 ~ '< 0.5',
      WeakMutationScore.VD.estimate > 0.5 ~ '> 0.5',
      TRUE ~ '= 0.5'),
    OutputCoverage.VD.estimate.category = case_when(
      OutputCoverage.VD.estimate < 0.5 ~ '< 0.5',
      OutputCoverage.VD.estimate > 0.5 ~ '> 0.5',
      TRUE ~ '= 0.5'))

# ######################################################
# Branch Coverage
# ######################################################

results %>%
  group_by(configuration) %>%
  summarise(mean_branch_coverage = mean(BranchCoverage),
            sd_branch_coverage = sd(BranchCoverage),
            median_branch_coverage = median(BranchCoverage),
            iqr_branch_coverage = IQR(BranchCoverage)) %>%
  arrange(mean_branch_coverage)

results %>%
  ggplot(aes(x = configuration, y = BranchCoverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Branch coverage') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))
ggsave("output/branch-coverage.pdf", width = 4.5, height = 3)

results %>%
  ggplot(aes(x = configuration, y = BranchCoverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  facet_grid(project ~ configuration, margins= "project", scales = "free_x")

# Plotting VD-estimate for significant cases
pairwise %>%
  filter(BranchCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  ggplot(aes(x = configuration.config, y = BranchCoverage.VD.estimate)) +
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
ggsave("output/branch-vd.pdf", width = 4.5, height = 3.5)

cat("Branch coverage effect size magnitude: \n")
branch_magnitudes <- pairwise %>%
  filter(BranchCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  group_by(configuration.config, BranchCoverage.VD.estimate.category, BranchCoverage.VD.magnitude) %>%
  summarise(count = n())
print(branch_magnitudes)

branch_magnitudes %>%
  filter(BranchCoverage.VD.magnitude == 'large')

# Analysis using Friedman's test

cat("Ranking for Branch Coverage:", "\n")

meanBranchCoverage <- results %>%
  group_by(project, bug_id, case, configuration) %>%
  summarise(mean_branch_coverage = mean(BranchCoverage),
            sd_branch_coverage = sd(BranchCoverage)) %>%
  as.data.frame()

apply_conover(meanBranchCoverage$mean_branch_coverage, 
              meanBranchCoverage$configuration, 
              meanBranchCoverage$case)

apply_friedman_test(meanBranchCoverage$mean_branch_coverage, 
                    meanBranchCoverage$configuration, 
                    meanBranchCoverage$case)

pdf("output/branch-friedman-nemenyi.pdf", width=7, height=4) 
meanBranchCoverage %>%
  select(case, configuration, mean_branch_coverage) %>%
  mutate(mean_branch_coverage = 1 - mean_branch_coverage) %>% #The lowest is the best in our case
  pivot_wider(names_from = configuration, values_from = mean_branch_coverage) %>%
  select(-case) %>%
  as.matrix() %>%
  nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
dev.off()


# ######################################################
# Output Coverage
# ######################################################

results %>%
  group_by(configuration) %>%
  summarise(mean_output_coverage = mean(OutputCoverage),
            sd_output_coverage = sd(OutputCoverage),
            median_output_coverage = median(OutputCoverage),
            iqr_output_coverage = IQR(OutputCoverage))

results %>%
  ggplot(aes(x = configuration, y = OutputCoverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Output coverage') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))
ggsave("output/output-coverage.pdf", width = 4.5, height = 3)

# Plotting VD-estimate for significant cases
pairwise %>%
  filter(OutputCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  ggplot(aes(x = configuration.config, y = OutputCoverage.VD.estimate)) +
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
ggsave("output/output-vd.pdf", width = 4.5, height = 3.5)

cat("Output coverage effect size magnitude: \n")
output_magnitudes <- pairwise %>%
  filter(OutputCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  group_by(configuration.config, OutputCoverage.VD.estimate.category, OutputCoverage.VD.magnitude) %>%
  summarise(count = n())
print(output_magnitudes)

output_magnitudes %>%
  filter(OutputCoverage.VD.magnitude == 'large')

cat("Target classes for which BBC has a large negative effect size: \n")
pairwise %>%
  filter(OutputCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL, OutputCoverage.VD.magnitude == 'large', OutputCoverage.VD.estimate.category == "< 0.5") %>%
  group_by(project, bug_id, case, TARGET_CLASS) %>%
  summarise(config.count = n())

# Analysis using Friedman's test

cat("Ranking for Output Coverage:", "\n")

meanOutputCoverage <- results %>%
  group_by(project, bug_id, case, configuration) %>%
  summarise(mean_output_coverage = mean(OutputCoverage),
            sd_output_coverage = sd(OutputCoverage)) %>%
  as.data.frame()

apply_conover(meanOutputCoverage$mean_output_coverage, 
              meanOutputCoverage$configuration, 
              meanOutputCoverage$case)

apply_friedman_test(meanOutputCoverage$mean_output_coverage, 
                    meanOutputCoverage$configuration, 
                    meanOutputCoverage$case)

pdf("output/output-friedman-nemenyi.pdf", width=7, height=4) 
meanOutputCoverage %>%
  select(case, configuration, mean_output_coverage) %>%
  mutate(mean_output_coverage = 1 - mean_output_coverage) %>% #The lowest is the best in our case
  pivot_wider(names_from = configuration, values_from = mean_output_coverage) %>%
  select(-case) %>%
  as.matrix() %>%
  nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
dev.off()

# ######################################################
# Implicit Methods Exceptions
# ######################################################

# Filter out cases for which the maximum number of Implicit Methods Exceptions is 0
resultsExceptionCoverage <- results %>%
  filter(!is.nan(ExceptionCoverage))

pairwiseExceptionCoverage <- resultsExceptionCoverage %>%
  filter(configuration != 'DynaMOSA') %>%
  inner_join(
    resultsExceptionCoverage %>%
      filter(configuration == 'DynaMOSA'),
    by = c('project', 'bug_id', 'case', 'TARGET_CLASS'),
    suffix = c('.config', '.base')) %>%
  group_by(project, bug_id, case, TARGET_CLASS, configuration.config)  %>%
  summarise(ExceptionCoverage.VD.magnitude = VD.A(ExceptionCoverage.config, ExceptionCoverage.base)$magnitude,
            ExceptionCoverage.VD.estimate = VD.A(ExceptionCoverage.config, ExceptionCoverage.base)$estimate,
            ExceptionCoverage.wilcox.test.pvalue = wilcox.test(ExceptionCoverage.config, ExceptionCoverage.base)$p.value) %>%
  mutate(ExceptionCoverage.VD.estimate.category = case_when(
      ExceptionCoverage.VD.estimate < 0.5 ~ '< 0.5',
      ExceptionCoverage.VD.estimate > 0.5 ~ '> 0.5',
      TRUE ~ '= 0.5'))

resultsExceptionCoverage %>%
  group_by(configuration) %>%
  summarise(mean_exception_coverage = mean(ExceptionCoverage),
            sd_exception_coverage = sd(ExceptionCoverage),
            median_exception_coverage = median(ExceptionCoverage),
            iqr_exception_coverage = IQR(ExceptionCoverage))

resultsExceptionCoverage %>%
  ggplot(aes(x = configuration, y = ExceptionCoverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Exception coverage') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))
ggsave("output/exception-coverage.pdf", width = 4.5, height = 3)

# Plotting VD-estimate for significant cases
pairwiseExceptionCoverage %>%
  filter(ExceptionCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  ggplot(aes(x = configuration.config, y = ExceptionCoverage.VD.estimate)) +
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
ggsave("output/exception-vd.pdf", width = 4.5, height = 3.5)

cat("Output coverage effect size magnitude: \n")
exception_magnitudes <- pairwiseExceptionCoverage %>%
  filter(ExceptionCoverage.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  group_by(configuration.config, ExceptionCoverage.VD.estimate.category, ExceptionCoverage.VD.magnitude) %>%
  summarise(count = n())
print(exception_magnitudes)

exception_magnitudes %>%
  filter(ExceptionCoverage.VD.magnitude == 'large')

# Analysis using Friedman's test

cat("Ranking for Exception Coverage:", "\n")

meanExceptionCoverage <- resultsExceptionCoverage %>%
  group_by(project, bug_id, case, configuration) %>%
  summarise(mean_exception_coverage = mean(ExceptionCoverage),
            sd_exception_coverage = sd(ExceptionCoverage)) %>%
  as.data.frame()

apply_conover(meanExceptionCoverage$mean_exception_coverage, 
              meanExceptionCoverage$configuration, 
              meanExceptionCoverage$case)

apply_friedman_test(meanExceptionCoverage$mean_exception_coverage, 
                    meanExceptionCoverage$configuration, 
                    meanExceptionCoverage$case)

pdf("output/exception-friedman-nemenyi.pdf", width=7, height=4) 
meanExceptionCoverage %>%
  select(case, configuration, mean_exception_coverage) %>%
  mutate(mean_exception_coverage = 1 - mean_exception_coverage) %>% #The lowest is the best in our case
  pivot_wider(names_from = configuration, values_from = mean_exception_coverage) %>%
  select(-case) %>%
  as.matrix() %>%
  nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
dev.off()


# ######################################################
# Weak mutation 
# ######################################################

results %>%
  group_by(configuration) %>%
  summarise(mean_branch_coverage = mean(WeakMutationScore),
            sd_branch_coverage = sd(WeakMutationScore),
            median_branch_coverage = median(WeakMutationScore),
            iqr_branch_coverage = IQR(WeakMutationScore))

results %>%
  ggplot(aes(x = configuration, y = WeakMutationScore)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Weak mutation score') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))
ggsave("output/weak-mutation-score.pdf", width = 4.5, height = 3)

# Plotting VD-estimate for significant cases
pairwise %>%
  filter(WeakMutationScore.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  ggplot(aes(x = configuration.config, y = WeakMutationScore.VD.estimate)) +
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
ggsave("output/weak-mutation-vd.pdf", width = 4.5, height = 3.5)

cat("Weak mutation score effect size magnitude: \n")
weak_mutation_magnitudes <- pairwise %>%
  filter(WeakMutationScore.wilcox.test.pvalue <= SIGNIFICANCE_LEVEL) %>%
  group_by(configuration.config, WeakMutationScore.VD.estimate.category, WeakMutationScore.VD.magnitude) %>%
  summarise(count = n())
print(weak_mutation_magnitudes)

weak_mutation_magnitudes %>%
  filter(WeakMutationScore.VD.magnitude == 'large')

# Analysis using Friedman's test

cat("Ranking for Weak mutation:", "\n")

meanWeakMutationScore <- results %>%
  group_by(project, bug_id, case, configuration) %>%
  summarise(mean_weak_mutation_score = mean(WeakMutationScore),
            sd_weak_mutation_score = sd(WeakMutationScore)) %>%
  as.data.frame()

apply_conover(meanWeakMutationScore$mean_weak_mutation_score, 
              meanWeakMutationScore$configuration, 
              meanWeakMutationScore$case)

apply_friedman_test(meanWeakMutationScore$mean_weak_mutation_score, 
                    meanWeakMutationScore$configuration, 
                    meanWeakMutationScore$case)

pdf("output/weak-mutation-friedman-nemenyi.pdf", width=7, height=4) 
meanWeakMutationScore %>%
  select(case, configuration, mean_weak_mutation_score) %>%
  mutate(mean_weak_mutation_score = 1 - mean_weak_mutation_score) %>% #The lowest is the best in our case
  pivot_wider(names_from = configuration, values_from = mean_weak_mutation_score) %>%
  select(-case) %>%
  as.matrix() %>%
  nemenyi(plottype = "vmcb", conf.level = 1.0 - SIGNIFICANCE_LEVEL)
dev.off()


# ######################################################
# Faults Coverage
# ######################################################

faults <- getFailureCoverage()

pairwise_faults <- faults %>%
  #filter(configuration != 'DynaMOSA') %>%
  inner_join(
    faults %>%
      filter(configuration == 'DynaMOSA'),
    by = c('project', 'bug_id', 'TARGET_CLASS'),
    suffix = c('.config', '.base')) %>%
  mutate(odds_ratio = computeOddsRatio(coverage_rate.config, coverage_rate.base),
         fisher_test = computeFishersExactTest(coverage_rate.config, coverage_rate.base)) %>%
  mutate(better = if_else(odds_ratio > 1, 1, 0, 0),
         nodiff = if_else(odds_ratio == 1, 1, 0, 0),
         worse = if_else(odds_ratio < 1, 1, 0, 0),
         reveraled = if_else(coverage_rate.config > 0, 1, 0, 0)) %>%
  group_by(configuration.config, configuration.base) %>%
  summarise(count = n(),
            count_revealed = sum(reveraled),
            bettercount = sum(better),
            nodiffcount = sum(nodiff),
            worsecount = sum(worse),
            mean_coverage_rate.config = mean(coverage_rate.config),
            sd_coverage_rate.config = sd(coverage_rate.config)) 

outputFile <- "output/table-real-faults.tex"
unlink(outputFile)
# Redirect cat outputs to file
sink(outputFile, append = TRUE, split = TRUE)
# cats
cat("% Total number of classes under test: ", pairwise_faults[[1, 'count']],"\n")
cat("\\begin{tabular}{ l | c c c | c c c }\n")
#cat("\\hline", "\n")
cat("\\textbf{Config.}", "&",
    "\\multicolumn{3}{c|}{\\textbf{Faults coverage}}", "&",
    "\\multicolumn{3}{c}{\\textbf{Odds ratio}}")
cat(" \\\\", "\n")
cat(" ", "&",
    "$\\#$", "&", "$\\overline{freq.}$", "&", "$\\sigma$", "&", 
    "$>1$", "&", "$=1$", "&", "$<1$")
cat(" \\\\", "\n")
cat("\\hline", "\n")
for(row in seq(from=1, to=nrow(pairwise_faults), by=1)){
  cat(as.character(pairwise_faults[[row, 'configuration.config']]), " & ", 
      pairwise_faults[[row, 'count_revealed']], " & ", 
      "$", formatC(pairwise_faults[[row, 'mean_coverage_rate.config']] *100 / TOTAL_RUNS, digits = 2, format = "f"), "\\%$", " & ", 
      "$", formatC(pairwise_faults[[row, 'sd_coverage_rate.config']] *100 / TOTAL_RUNS, digits = 2, format = "f"), "\\%$", " & ", 
      if_else(pairwise_faults[[row, 'bettercount']] > 0, as.character(pairwise_faults[[row, 'bettercount']]), '-', '-') , " & ",
      if_else(pairwise_faults[[row, 'nodiffcount']] > 0, as.character(pairwise_faults[[row, 'nodiffcount']]), '-', '-') , " & ",
      if_else(pairwise_faults[[row, 'worsecount']] > 0, as.character(pairwise_faults[[row, 'worsecount']]), '-', '-'), sep ="")
  cat(" \\\\", "\n")
}
cat("\\end{tabular}")
sink()


# ########################################################################
# Analysis of org.apache.commons.cli.HelpFormatter in Cli-31 and Cli-32
# ########################################################################

Cli31 <- results %>%
  filter(project == 'Cli', bug_id == 31 ,TARGET_CLASS == 'org.apache.commons.cli.HelpFormatter')

Cli31 %>%
  group_by(configuration) %>%
  summarise(mean(OutputCoverage), sd(OutputCoverage))

Cli31 %>%
  ggplot(aes(x = configuration, y = OutputCoverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Output coverage') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))

faults %>%
  filter(project == 'Cli', bug_id == 31 ,TARGET_CLASS == 'org.apache.commons.cli.HelpFormatter')

Cli31 %>%
  pivot_longer(cols = c(BranchCoverage, OutputCoverage, ExceptionCoverage, WeakMutationScore),
               names_to = "Criterion", values_to = "Coverage") %>%
  ggplot(aes(x = configuration, y = Coverage)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  ) +
  xlab(NULL) +
  ylab('Output coverage') +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5)) +
  facet_wrap(.~Criterion, ncol = 2)



Cli3132 <- results %>%
  filter(project == 'Cli', bug_id %in% c(31, 32) ,TARGET_CLASS == 'org.apache.commons.cli.HelpFormatter')

Cli3132 %>%
  group_by(configuration) %>%
  summarise(mean(OutputCoverage), sd(OutputCoverage))

Cli3132 %>%
  pivot_longer(cols = c(BranchCoverage, OutputCoverage, ExceptionCoverage, WeakMutationScore),
               names_to = "Criterion", values_to = "Coverage") %>%
  ggplot(aes(x = configuration, y = Coverage, fill = as.factor(bug_id))) +
  geom_boxplot() +
  xlab(NULL) +
  ylab(NULL) +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5)) +
  facet_wrap(.~Criterion, ncol = 2)

Cli3132 %>%
  ggplot(aes(x = configuration, y = Size, fill = as.factor(bug_id))) +
  geom_boxplot() +
  xlab(NULL) +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))

Cli3132 %>%
  ggplot(aes(x = configuration, y = Length, fill = as.factor(bug_id))) +
  geom_boxplot() +
  xlab(NULL) +
  theme(axis.text.x = element_text(angle = 55, vjust = 0.5))

Cli3132Pairwise <- pairwise %>%
  filter(project == 'Cli', bug_id %in% c(31, 32) ,TARGET_CLASS == 'org.apache.commons.cli.HelpFormatter')

Cli3132pairwiseExceptionCoverage <- pairwiseExceptionCoverage %>%
  filter(project == 'Cli', bug_id %in% c(31, 32) ,TARGET_CLASS == 'org.apache.commons.cli.HelpFormatter')


# ####################################################################
# Correlation analysis between output coverage and exception coverage 
# ####################################################################

cor.test(results$OutputCoverage, results$ExceptionCoverage, method="kendall")

cor.test(results$OutputCoverage, results$ExceptionCoverage, method="spearman")






