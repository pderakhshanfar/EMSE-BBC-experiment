source('dataclean.r')

library(ggplot2)
library(xtable)

subjects <- getSubjects()

cat('Projects:', '\n')
subjects %>%
  distinct(project_id, bug_id) %>%
  group_by(project_id) %>%
  summarise(bugs = n())


df <- subjects %>%
  group_by(project_id, bug_id, class, ncss_class) %>%
  summarise(methods = n(),
            wmc = sum(ccn)) %>%
  group_by(project_id) %>%
  summarise(ncss_class_avg = mean(ncss_class),
            ncss_class_sd = sd(ncss_class),
            ncss_class_median = median(ncss_class), 
            ncss_class_IQR = IQR(ncss_class),
            ncss_class_min = min(ncss_class),
            ncss_class_max = max(ncss_class),
            methods_avg = mean(methods),
            methods_sd = sd(methods),
            methods_median = median(methods), 
            methods_IQR = IQR(methods),
            methods_min = min(methods),
            methods_max = max(methods),
            wmc_avg = mean(wmc),
            wmc_sd = sd(wmc),
            wmc_median = median(wmc), 
            wmc_IQR = IQR(wmc),
            wmc_min = min(wmc),
            wmc_max = max(wmc)) %>%
  full_join(subjects %>%  
              group_by(project_id) %>%
              summarise(ccn_avg = mean(ccn),
                        ccn_sd = sd(ccn),
                        ccn_median = median(ccn), 
                        ccn_IQR = IQR(ccn),
                        ccn_min = min(ccn),
                        ccn_max = max(ccn))) %>%
  full_join(subjects %>%  
              distinct(project_id, bug_id, class) %>%
              group_by(project_id) %>%
              summarise(classes = n()))

outputFile <- "../../../EMSE-extension/table-subjects-unit-testing.tex"
unlink(outputFile)
# Redirect cat outputs to file
sink(outputFile, append = TRUE, split = TRUE)
# cats
cat("\\begin{tabular}{ l | r | r c | r c | r c | r c }\n")
#cat("\\hline", "\n")
cat("\\textbf{Project}", "&",
    "\\textbf{CUTs}", "&",
    "\\multicolumn{2}{c|}{\\textbf{NCSS}}", "&",
    "\\multicolumn{2}{c|}{\\textbf{Methods}}", "&",
    "\\multicolumn{2}{c|}{\\textbf{WMC}}", "&",
    "\\multicolumn{2}{c}{\\textbf{CCN}}")
cat(" \\\\", "\n")
cat(" ", "&",
    " ", "&",
    "$\\overline{x}(\\sigma)$", "&", "range", "&", 
    "$\\overline{x}(\\sigma)$", "&", "range", "&", 
    "$\\overline{x}(\\sigma)$", "&", "range", "&", 
    "$\\overline{x}(\\sigma)$", "&", "range")
cat(" \\\\", "\n")
cat("\\hline", "\n")
for(row in seq(from=1, to=nrow(df), by=1)){
  cat(as.character(df[[row, 'project_id']]), " & ", 
      df[[row, 'classes']], " & ", 
      formatC(df[[row, 'ncss_class_avg']], digits = 1, format = "f"), "(", 
      formatC(df[[row, 'ncss_class_sd']], digits = 1, format = "f"), ") & [", 
      formatC(df[[row, 'ncss_class_min']], digits = 0, format = "f"), ",", 
      formatC(df[[row, 'ncss_class_max']], digits = 0, format = "f"), "] & ",
      formatC(df[[row, 'methods_avg']], digits = 1, format = "f"), "(", 
      formatC(df[[row, 'methods_sd']], digits = 1, format = "f"), ") & [", 
      formatC(df[[row, 'methods_min']], digits = 0, format = "f"), ",", 
      formatC(df[[row, 'methods_max']], digits = 0, format = "f"), "] & ",
      formatC(df[[row, 'wmc_avg']], digits = 1, format = "f"), "(", 
      formatC(df[[row, 'wmc_sd']], digits = 1, format = "f"), ") & [", 
      formatC(df[[row, 'wmc_min']], digits = 0, format = "f"), ",", 
      formatC(df[[row, 'wmc_max']], digits = 0, format = "f"), "] & ",
      formatC(df[[row, 'ccn_avg']], digits = 1, format = "f"), "(", 
      formatC(df[[row, 'ccn_sd']], digits = 1, format = "f"), ") & [", 
      formatC(df[[row, 'ccn_min']], digits = 0, format = "f"), ",", 
      formatC(df[[row, 'ccn_max']], digits = 0, format = "f"), "]", sep = "")
  cat(" \\\\", "\n")
}
cat("\\end{tabular}")
sink()

            
            


