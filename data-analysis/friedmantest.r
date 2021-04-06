library(PMCMR)
library(tsutils)

plot_using_friedman_and_nemenyi <- function(avgCBCPerCase){
  cases <- unique(avgCBCPerCase$case)
  testsuites <- unique(avgCBCPerCase$testsuite)
  clean_data <- matrix(, nrow = length(cases), ncol = length(testsuites))

    case_index = 0
  for (c in cases){
    tool_index = 0
    case_index = case_index + 1
    df <- avgCBCPerCase %>%
      filter(case == c)
    for (t in testsuites){
      tool_index = tool_index + 1
      df2 <- df %>%
        filter(testsuite == t)
      if (nrow(df2) > 1){
        cat (paste0("Error! more than one row: ",nrow(df2))) 
      }else{
        value = df2$avgCBC[1]
        # So, We do this because for us highest is the best
        clean_data[case_index,tool_index] <- 1 - value
        cat(paste0(df2$case[1]," + ",df2$testsuite[1], " + ", value ,"\n"))
      }
    }
  }
  
  colnames(clean_data) <- testsuites
  p <- nemenyi(clean_data,conf.level=0.95,plottype="vmcb")
  return(p)
  
}

apply_conover <- function(dependent, groups, blocks){
  res <- friedman.test(y = factor(dependent), groups = factor(groups), blocks = factor(blocks))
  print(res)
  res = as.data.frame(do.call(rbind, res))
  # apply the post-hoc Conover's predecure 
  res <- posthoc.friedman.conover.test(y = as.numeric(dependent), groups = factor(groups), blocks = factor(blocks), p.adjust.method="bonferroni")
  print(res)
  res = as.data.frame(res$p.value)
  return(res)
}

apply_friedman_test <- function(dependent, groups, blocks){
  # compute final ranking
  # y: numeric version of dependent
  y = as.numeric(dependent)
  # k: number of configurations
  k <- nlevels(factor(groups))
  y <- matrix(unlist(split(y, blocks)), ncol = k, byrow = TRUE)
  y <- y[complete.cases(y), ]
  n <- nrow(y)
  r <- t(apply(y, 1, rank))
  # after the previous command, we have the ranking for each observation. In these rankings the lowest is the best (opposite of our goal)
  # So, We do this because for us highest is the best
  r <- k - r + 1
  # tools: configurations
  tools <- unique(groups)
  colnames(r) = tools
  r <- as.data.frame(r)
  # apply a Mean on all of the observations for each configuration
  ranking <- as.data.frame(colMeans(r))
  colnames(ranking) <- "Rank"
  return(ranking)
}

# It performs a sample ranking for each of the observations (here each case). In this ranking lowest is the best.
# for example, ranking of these values c(4,7,2,9) is 2(second best),3 (third best), 2 (the best), 4 (last)
# When we have same values in the list that we should rank, we put the average ranking for each of the tied ones.
# for example, ranking of these values c(4,2,2,9) is 3,1.5 (avg of 1 and 2), 1.5 (avg. of 1 and 2), 4
# After we get the ranknig for each observation, we reverse the rankings because the highest is the best in our case.
# Finally, the average of each configuration's ranking in all of the observations is the final ranking for that configuration
