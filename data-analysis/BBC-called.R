source('dataclean.r')
source('table.R')


library(ggplot2)

raw_df <- getBBCDF()


raw_df <- raw_df %>%
  mutate(is_activated = ifelse(activated >0,1,0),
         is_useful = ifelse(useful>0,1,0),
         activation_rate_called = activated/called,
         usefulness_rate_called = useful/called,
         activation_rate_eval = activated/as.numeric(ff_eval),
         usefulness_rate_eval = useful/as.numeric(ff_eval),
         usefulness_rate_activated = useful/activated,
         )
### TEMP

temp <- raw_df %>%
  group_by(project_id, bug_id, target_class, execution_id) %>%
  summarise(activated_objectives = sum(is_activated),
            used_for_objectives = sum(is_useful),
            total_objectives = n()) %>%
  mutate(activation_perc = activated_objectives/total_objectives,
         usefulness_perc = used_for_objectives/total_objectives)



objectives_df <- temp %>%
  group_by(project_id) %>% 
  summarise(
    # activation rate
    activation_mean = mean(activation_perc),
    activation_median = median(activation_perc),
    activation_sd = sd(activation_perc),
    activation_min = min(activation_perc),
    activation_max = max(activation_perc),
    # usefulness rate
    usefulness_mean = mean(usefulness_perc),
    usefulness_median = median(usefulness_perc),
    usefulness_sd = sd(usefulness_perc),
    usefulness_min = min(usefulness_perc),
    usefulness_max = max(usefulness_perc)
  )

p <- temp %>%
  ggplot(aes(x = project_id, y = usefulness_perc)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  )
ggsave("output/motiv/motiv_BBC_useful_perc.pdf", width = 16, height = 4)
  

p <- temp %>%
  ggplot(aes(x = project_id, y = activation_perc)) +
  geom_boxplot() +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 0,
    color = "black",
    fill = "white"
  )
ggsave("output/motiv/motiv_BBC_actiavtion_perc.pdf", width = 16, height = 4)

df_total <- raw_df %>%
  filter(is_activated == 1)%>%
  group_by(project_id, bug_id, target_class, execution_id) %>%
  summarise(useeval = mean(usefulness_rate_eval),
            usecall = mean(usefulness_rate_called),
            activation = mean(activation_rate_eval),
            useact = mean(usefulness_rate_activated))



# df_total_temp <- df_total %>%
#   filter(!is.na(useact))


means_and_sds_df <- df_total %>%
  filter(!is.na(useact)) %>% 
  group_by(project_id) %>% 
  summarise(
    # activation rate
    activation_mean = mean(activation),
    activation_median = median(activation),
    activation_sd = sd(activation),
    activation_min = min(activation),
    activation_max = max(activation),
    # usefulness rate
    usefulness_mean = mean(useeval),
    usefulness_median = median(useeval),
    usefulness_sd = sd(useeval),
    usefulness_min = min(useeval),
    usefulness_max = max(useeval)
  )

generate_motiv_table(means_and_sds_df)
# temp2 <- df_total_temp %>%
#   group_by(project_id) %>%
#   summarise(avg_rate = mean(useact),
#             sd_rate = sd(useact))
# 
# temp <- df_total %>%
#   group_by(project_id) %>%
#   summarise(avg_useeval = mean(useeval),
#             median_useeval = median(useeval),
#             sd_useeval = sd(useeval),
#             avg_activation = mean(activation),
#             median_activation = median(activation),
#             sd_activation = sd(activation))


p <- df_total %>%
  ggplot(aes(x = project_id, y = useeval)) +
  geom_boxplot()
ggsave("output/trial/motiv_BBC_called.pdf", width = 16, height = 4)


p_scale <-df_total %>%
  ggplot(aes(x = project_id, y = useeval)) +
  geom_boxplot() +
  scale_y_log10()

ggsave("output/motiv/motiv_BBC_called_log10_scaled.pdf", width = 16, height = 4)



p <- df_total %>%
  ggplot(aes(x = project_id, y = activation)) +
  geom_boxplot()
ggsave("output/motiv/motiv_BBC_activated.pdf", width = 16, height = 4)

p <- df_total %>%
  ggplot(aes(x = project_id, y = activation)) +
  geom_boxplot() +
  scale_y_log10()
ggsave("output/motiv/motiv_BBC_activated_log10_scaled.pdf", width = 16, height = 4)


### Cor

# for bbc 

cor_df <- df_total %>%
  group_by(project_id,bug_id,target_class) %>%
  summarise(activation_mean = mean(activation),
                usefulness_mean = mean(useeval))
results_df <- getResults() %>%
  filter(
    configuration =="DynaMOSA" |
    configuration == "bbc-0.5"
  ) %>%
  select(project,bug_id,configuration,execution_idx,TARGET_CLASS,BranchCoverage)

branchCoverag_diff <- results_df %>% 
  filter(configuration =="DynaMOSA") %>% 
  inner_join(
    results_df %>% 
      filter(configuration =="bbc-0.5"),
    by = c('project', 'bug_id', 'TARGET_CLASS'),
    suffix = c('.dynamosa', '.bbc')
  ) %>% 
  filter(execution_idx.bbc == execution_idx.dynamosa) %>%
  mutate(diff = BranchCoverage.bbc - BranchCoverage.dynamosa) %>%
  group_by(project,bug_id,TARGET_CLASS) %>%
  summarise(avg_diff = mean(diff)) %>%
  rename(target_class = TARGET_CLASS ,
         project_id = project)


final_df <- cor_df %>%
  inner_join(
    branchCoverag_diff,
    by=c('project_id','bug_id','target_class')
  )


cor.test(final_df$usefulness_mean, final_df$avg_diff, method="spearman")
