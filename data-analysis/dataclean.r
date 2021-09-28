# Contains functions to produce a clean/easy to process dataframe from the input and 
# output csv files.
# authors: Pouria Derakhshanfar, Xavier Devroey

library(tidyverse)

TOTAL_RUNS = 30
COLOR_PALETTE = "RdBu" # Color blind friendly colors (http://colorbrewer2.org/)
SIGNIFICANCE_LEVEL = 0.01

# Normalize data between [0;1]
normalize <- function(x) {
  max <- 1.0 * max(x)
  min <- 1.0 * min(x)
  if(max == 0 || max == min){
    return(NA)
  } else {
    return((x - min) / (max - min))
  }
}

# Returns the list of classes under test used for the evaluation
getSubjects <- function(){
  csvFile='../data/subjects.csv'
  df <- read.csv(csvFile, stringsAsFactors = TRUE)
  return(df)
}


getBBCDF <- function(){
  files <- c("../data/bbc_triggered-part1.csv", "../data/bbc_triggered-part2.csv", 
             "../data/bbc_triggered-part3.csv", "../data/bbc_triggered-part4.csv")
  tables <- lapply(files, function(x){read.csv(file = x, stringsAsFactors = TRUE, na.strings = c("null"))})
  df <- do.call(rbind, tables) %>%
    mutate(X = NULL) %>%
    filter(! is.na(ff_eval))
  return(df)
}

getResultsWithInterval <- function(){
  csvFile='../results/results-with_intervals.csv'
  df <- read.csv(csvFile, stringsAsFactors = TRUE)
  return(df)
}

# Returns the results of the evaluation
getResults <- function(){
  csvFile='../results/results.csv'
  df <- read.csv(csvFile, stringsAsFactors = TRUE) %>%
    mutate(configuration = recode_factor(configuration,
      `BBC-F0-10`= 'bbc-0.1', `BBC-F0-20`= 'bbc-0.2', `BBC-F0-30`= 'bbc-0.3',  
      `BBC-F0-40`= 'bbc-0.4', `BBC-F0-50`= 'bbc-0.5', `BBC-F0-60`= 'bbc-0.6',  
      `BBC-F0-70`= 'bbc-0.7', `BBC-F0-80`= 'bbc-0.8', `BBC-F0-90`= 'bbc-0.9',
      `BBC-F0-100`= 'bbc-1.0', `default`= 'DynaMOSA'),
      case = paste0(as.character(project), '-', bug_id)) %>%
    # Normalise the Implicit_MethodExceptions
    group_by(project, bug_id, TARGET_CLASS) %>%
    mutate(ExceptionCoverage = (1.0 * Implicit_MethodExceptions) / max(Implicit_MethodExceptions)) %>%
    ungroup()
  return(df)
}


getFailureCoverage <- function(){
  csvFile='../data/failure_coverage_ratio.csv'
  df <- read.csv(csvFile, stringsAsFactors = TRUE) %>%
    rename(configuration = tool, TARGET_CLASS = target_class) %>%
    mutate(bug_id = as.numeric(str_extract(as.character(project), "[0-9]+$")),
           project = as.factor(str_replace(as.character(project), "-[0-9]+$", "")),
           configuration = recode_factor(configuration,
              `BBC-F0-10`= 'bbc-0.1', `BBC-F0-20`= 'bbc-0.2', `BBC-F0-30`= 'bbc-0.3',  
              `BBC-F0-40`= 'bbc-0.4', `BBC-F0-50`= 'bbc-0.5', `BBC-F0-60`= 'bbc-0.6',  
              `BBC-F0-70`= 'bbc-0.7', `BBC-F0-80`= 'bbc-0.8', `BBC-F0-90`= 'bbc-0.9',
              `BBC-F0-100`= 'bbc-1.0', `default`= 'DynaMOSA')) %>%
    select(-X, -isAssertion)
  return(df)
}


computeOddsRatio <- Vectorize(function(count1, count2){
  m <- matrix(c(count1, TOTAL_RUNS - count1,
                count2, TOTAL_RUNS - count2), ncol = 2, byrow = TRUE)
  dimnames(m) <- list('Configuration' = c('conf1', 'conf2'),
                      'Reproduced' = c('yes', 'no'))
  or <- odds.ratio(m, level = 1.0 - SIGNIFICANCE_LEVEL)
  if(or$p <= SIGNIFICANCE_LEVEL){
    return(or$OR)
  } else {
    return(NA)
  }
})

computeFishersExactTest <- Vectorize(function(count1, count2){
  m <- matrix(c(count1, TOTAL_RUNS - count1,
                count2, TOTAL_RUNS - count2), ncol = 2, byrow = TRUE)
  dimnames(m) <- list('Configuration' = c('conf1', 'conf2'),
                      'Reproduced' = c('yes', 'no'))
  or <- odds.ratio(m, level = 1.0 - SIGNIFICANCE_LEVEL)
  return(or$p)
})


stat_box_data <- function(y, upper_limit = 1.0) {
  return( 
    data.frame(
      y = 0.95 * upper_limit,
      label = paste0('n=', length(y)),
      angle = 55
    )
  )
}
