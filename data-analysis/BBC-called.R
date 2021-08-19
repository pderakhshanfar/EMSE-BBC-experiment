source('dataclean.r')


library(ggplot2)

raw_df <- getBBCDF()


raw_df <- raw_df %>%
  mutate(is_activated = ifelse(activated >0,1,0),
         is_useful = ifelse(useful>0,1,0),
         activation_rate_called = activated/called,
         usefulness_rate_called = useful/called,
         activation_rate_eval = activated/as.numeric(ff_eval),
         usefulness_rate_eval = useful/as.numeric(ff_eval))




df <- raw_df %>%
  group_by(project_id,bug_id,target_class) %>%
  summarise(avg_call = median(triggered))


df_total <- raw_df %>%
  group_by(project_id, bug_id, target_class, execution_id) %>%
  summarise(call = mean(usefulness_rate_eval))


temp <- df_total %>%
  group_by(project_id) %>%
  summarise(avg_use = mean(call))


p <- df_total %>%
  ggplot(aes(x = project_id, y = call)) +
  geom_boxplot()