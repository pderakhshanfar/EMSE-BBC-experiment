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