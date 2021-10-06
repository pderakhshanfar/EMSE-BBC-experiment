source('dataclean.r')
source('table.R')


library(ggplot2)

raw_df <- getBBCDF()

raw_df <- raw_df %>%
  mutate(is_activated = if_else(activated > 0, 1, 0),
         is_useful = if_else(useful > 0, 1, 0),
         activation_rate_called = activated/called,
         usefulness_rate_called = useful/called,
         activation_per_eval = activated/ff_eval,
         usefulness_per_eval = useful/ff_eval,
         usefulness_rate_activated = useful/activated,
         )

raw_df %>%
  summarise(called_total = sum(called),
         activated_total = sum(activated), 
         useful_total = sum(useful),
         ff_eval_total = sum(ff_eval)) %>% 
  mutate(useful_rate_called = useful_total / called_total,
         useful_rate_activated = useful_total / activated_total, 
         useful_per_ffeval = useful_total / ff_eval_total)

# General statistics about the BBC calls, activations, usefulness and FF evaluations

general_stats <- raw_df %>%
  rbind(
    raw_df %>%
      mutate(project_id = "(all)")
  ) %>% 
  group_by(project_id) %>%
  summarise(
    objectives = n_distinct(objective),
    ff_eval_min = min(ff_eval),
    ff_eval_median = median(ff_eval),
    ff_eval_IQR = IQR(ff_eval),
    ff_eval_max = max(ff_eval),
    ff_eval_mean = mean(ff_eval),
    ff_eval_sd = sd(ff_eval),
    called_min = min(called),
    called_median = median(called),
    called_IQR = IQR(called),
    called_max = max(called),
    called_mean = mean(called),
    called_sd = sd(called),
    activated_min = min(activated),
    activated_median = median(activated),
    activated_IQR = IQR(activated),
    activated_max = max(activated),
    activated_mean = mean(activated),
    activated_sd = sd(activated),
    useful_min = min(useful),
    useful_median = median(useful),
    useful_IQR = IQR(useful),
    useful_max = max(useful),
    useful_mean = mean(useful),
    useful_sd = sd(useful)
  )

print(general_stats)

outputFile <- "output/tables/table-general-stats-bbc-preanalysis.tex"
unlink(outputFile)
# Redirect cat outputs to file
sink(outputFile, append = TRUE, split = TRUE)
# cats
cat("% Pre-analysis","\n")
cat("\\begin{tabular}{ l | r | r r | r r | r r | r r }\n")
#cat("\\hline", "\n")
cat("\\textbf{Project}", "&",
    "\\textbf{Obj.}", "&",
    "\\multicolumn{2}{c|}{\\textbf{Fitness eval.}}", "&",
    "\\multicolumn{2}{c|}{\\textbf{BBC calls}}", "&",
    "\\multicolumn{2}{c|}{\\textbf{BBC active}}", "&",
    "\\multicolumn{2}{c}{\\textbf{BBC useful}}")
cat(" \\\\", "\n")
cat(" ", "&", " ", "&",
    "$\\overline{count}$", "&", "$\\sigma$", "&", 
    "$\\overline{count}$", "&", "$\\sigma$", "&", 
    "$\\overline{count}$", "&", "$\\sigma$", "&", 
    "$\\overline{count}$", "&", "$\\sigma$")
cat(" \\\\", "\n")
cat("\\hline", "\n")
for(row in seq(from=1, to=nrow(general_stats), by=1)){
  cat(as.character(general_stats[[row, 'project_id']]), " & ", 
      general_stats[[row, 'objectives']], " & ", 
      formatC(general_stats[[row, 'ff_eval_mean']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'ff_eval_sd']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'called_mean']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'called_sd']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'activated_mean']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'activated_sd']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'useful_mean']], digits = 2, format = "f"), " & ", 
      formatC(general_stats[[row, 'useful_sd']], digits = 2, format = "f"), sep ="")
  cat(" \\\\", "\n")
}
cat("\\end{tabular}")
sink()


# Number of time the call to BBC has been useful per fitness evaluation

p <- raw_df %>%
  rbind(
    raw_df %>%
      mutate(project_id = "(all)")
  ) %>%
  filter(usefulness_per_eval > 0) %>%
  ggplot(aes(x = project_id, y = usefulness_per_eval)) +
  geom_boxplot() +
  scale_y_log10() +
  xlab(NULL) +
  ylab("Usefulness per fit. eval. (log scale)") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

ggsave("output/usefulness-per-fiteval.pdf", plot = p, width = 7, height = 4.5)

df <- raw_df %>%
  rbind(
    raw_df %>%
      mutate(project_id = "(all)")
  ) %>%
  filter(is_activated == 1)%>%
  group_by(project_id) %>%
  summarise(count = n(),
            useful_count = sum(is_useful),
            usefulness_per_eval_mean = mean(usefulness_per_eval),
            usefulness_per_eval_sd = sd(usefulness_per_eval),
            usefulness_per_eval_min = min(usefulness_per_eval, na.rm = TRUE), 
            usefulness_per_eval_med = median(usefulness_per_eval, na.rm = TRUE),
            usefulness_per_eval_IQR = IQR(usefulness_per_eval, na.rm = TRUE), 
            usefulness_per_eval_max = max(usefulness_per_eval, na.rm = TRUE)) 

print(df)

### TEMP
# 
# temp <- raw_df %>%
#   group_by(project_id, bug_id, target_class, execution_id) %>%
#   summarise(activated_objectives = sum(is_activated),
#             used_for_objectives = sum(is_useful),
#             total_objectives = n()) %>%
#   mutate(activation_perc = activated_objectives/total_objectives,
#          usefulness_perc = used_for_objectives/total_objectives)
# 
# 
# 
# objectives_df <- temp %>%
#   group_by(project_id) %>% 
#   summarise(
#     # activation rate
#     activation_mean = mean(activation_perc),
#     activation_median = median(activation_perc),
#     activation_sd = sd(activation_perc),
#     activation_min = min(activation_perc),
#     activation_max = max(activation_perc),
#     # usefulness rate
#     usefulness_mean = mean(usefulness_perc),
#     usefulness_median = median(usefulness_perc),
#     usefulness_sd = sd(usefulness_perc),
#     usefulness_min = min(usefulness_perc),
#     usefulness_max = max(usefulness_perc)
#   )
# 
# p <- temp %>%
#   ggplot(aes(x = project_id, y = usefulness_perc)) +
#   geom_boxplot() +
#   stat_summary(
#     fun = mean,
#     geom = "point",
#     shape = 0,
#     color = "black",
#     fill = "white"
#   )
# ggsave("output/motiv/motiv_BBC_useful_perc.pdf", width = 16, height = 4)
#   
# 
# p <- temp %>%
#   ggplot(aes(x = project_id, y = activation_perc)) +
#   geom_boxplot() +
#   stat_summary(
#     fun = mean,
#     geom = "point",
#     shape = 0,
#     color = "black",
#     fill = "white"
#   )
# ggsave("output/motiv/motiv_BBC_actiavtion_perc.pdf", width = 16, height = 4)
# 
# df_total <- raw_df %>%
#   filter(is_activated == 1)%>%
#   group_by(project_id, bug_id, target_class, execution_id) %>%
#   summarise(useeval = mean(usefulness_per_eval),
#             usecall = mean(usefulness_rate_called),
#             activation = mean(activation_per_eval),
#             useact = mean(usefulness_rate_activated))
# 
# 
# 
# # df_total_temp <- df_total %>%
# #   filter(!is.na(useact))
# 
# 
# means_and_sds_df <- df_total %>%
#   filter(!is.na(useact)) %>% 
#   group_by(project_id) %>% 
#   summarise(
#     # activation rate
#     activation_mean = mean(activation),
#     activation_median = median(activation),
#     activation_sd = sd(activation),
#     activation_min = min(activation),
#     activation_max = max(activation),
#     # usefulness rate
#     usefulness_mean = mean(useeval),
#     usefulness_median = median(useeval),
#     usefulness_sd = sd(useeval),
#     usefulness_min = min(useeval),
#     usefulness_max = max(useeval)
#   )
# 
# generate_motiv_table(means_and_sds_df)
# # temp2 <- df_total_temp %>%
# #   group_by(project_id) %>%
# #   summarise(avg_rate = mean(useact),
# #             sd_rate = sd(useact))
# # 
# # temp <- df_total %>%
# #   group_by(project_id) %>%
# #   summarise(avg_useeval = mean(useeval),
# #             median_useeval = median(useeval),
# #             sd_useeval = sd(useeval),
# #             avg_activation = mean(activation),
# #             median_activation = median(activation),
# #             sd_activation = sd(activation))
# 
# 
# p <- df_total %>%
#   ggplot(aes(x = project_id, y = useeval)) +
#   geom_boxplot()
# ggsave("output/trial/motiv_BBC_called.pdf", width = 16, height = 4)
# 
# 
# p_scale <-df_total %>%
#   ggplot(aes(x = project_id, y = useeval)) +
#   geom_boxplot() +
#   scale_y_log10()
# 
# ggsave("output/motiv/motiv_BBC_called_log10_scaled.pdf", width = 10, height = 4)
# 
# 
# 
# p <- df_total %>%
#   ggplot(aes(x = project_id, y = activation)) +
#   geom_boxplot()
# ggsave("output/motiv/motiv_BBC_activated.pdf", width = 16, height = 4)
# 
# p <- df_total %>%
#   ggplot(aes(x = project_id, y = activation)) +
#   geom_boxplot() +
#   scale_y_log10()
# ggsave("output/motiv/motiv_BBC_activated_log10_scaled.pdf", width = 16, height = 4)
# 
# 
# ### Cor
# 
# # for bbc 
# 
# cor_df <- df_total %>%
#   group_by(project_id,bug_id,target_class) %>%
#   summarise(activation_mean = mean(activation),
#                 usefulness_mean = mean(useeval))
# results_df <- getResults() %>%
#   filter(
#     configuration =="DynaMOSA" |
#     configuration == "bbc-0.5"
#   ) %>%
#   select(project,bug_id,configuration,execution_idx,TARGET_CLASS,BranchCoverage)
# 
# branchCoverag_diff <- results_df %>% 
#   filter(configuration =="DynaMOSA") %>% 
#   inner_join(
#     results_df %>% 
#       filter(configuration =="bbc-0.5"),
#     by = c('project', 'bug_id', 'TARGET_CLASS'),
#     suffix = c('.dynamosa', '.bbc')
#   ) %>% 
#   filter(execution_idx.bbc == execution_idx.dynamosa) %>%
#   mutate(diff = BranchCoverage.bbc - BranchCoverage.dynamosa) %>%
#   group_by(project,bug_id,TARGET_CLASS) %>%
#   summarise(avg_diff = mean(diff)) %>%
#   rename(target_class = TARGET_CLASS ,
#          project_id = project)
# 
# 
# final_df <- cor_df %>%
#   inner_join(
#     branchCoverag_diff,
#     by=c('project_id','bug_id','target_class')
#   )
# 
# 
# cor.test(final_df$usefulness_mean, final_df$avg_diff, method="spearman")
