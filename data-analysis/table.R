

generate_motiv_table <- function(table_data){
  #Print the table
  outputFile <- "output/tables/BBC-usefulness.tex"
  unlink(outputFile)
  # Redirect cat outputs to file
  sink(outputFile, append = TRUE, split = TRUE)
  # cat outputs
  cat("\\begin{tabular}{ l | ccccc | ccccc }\n")
  cat("\\hline", "\n")
  cat("\\textbf{Project}", "&",
      "\\multicolumn{5}{c|}{\\textbf{BBC activation/fitness evaluation}}","&",
      "\\multicolumn{5}{c}{\\textbf{BBC usefulness/fitness evaluation }}")
  cat(" \\\\", "\n")
  cat(" ", "&",
      #activation
      "median", "&", 
      "$\\overline{\\text{rate}}$", "&", 
      "$\\sigma$", "&", 
      "min", "&", 
      "max", "&",
      #usefulness
      "median", "&", 
      "$\\overline{\\text{rate}}$", "&", 
      "$\\sigma$", "&", 
      "min", "&", 
      "max")
  cat(" \\\\", "\n")
  cat("\\hline", "\n")
  for(row in seq(from=2, to=nrow(table_data),by=1)){
    cat(as.character(table_data[[row, 'project_id']]), "&", 
        # activation
        formatC(table_data[[row, 'activation_median']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'activation_mean']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'activation_sd']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'activation_min']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'activation_max']], digits=2, format="f", big.mark = ','), "&",
        #usefulness
        formatC(table_data[[row, 'usefulness_median']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'usefulness_mean']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'usefulness_sd']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'usefulness_min']], digits=2, format="f", big.mark = ','), "&", 
        formatC(table_data[[row, 'usefulness_max']], digits=2, format="f", big.mark = ',')
    )
    cat(" \\\\", "\n")
  }
  cat(" \\\\", "\n")
  cat("\\end{tabular}")
  # Restore cat outputs to console
  sink()
}