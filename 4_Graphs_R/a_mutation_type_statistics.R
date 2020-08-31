library(xtable)
library(dplyr)

data_path_equal_fitness <- "../3_a_LocalMachineDataProcessing_Python/equal_mutation_type.csv"

data_equal <- read.csv(data_path_equal_fitness, na.strings = "NONE")

data_equal$scenario <- factor(data_equal$scenario,
                                      levels=c("noSelPressureBoth", "independentAddition",
                                               "lockstep", "oneOffLockstep", 
                                               "bFollowsA", "matchingBitsLockstep"),
                                      labels = c("No Selection Pressure", "Additive Evolution",
                                                 "Zero-Off Lockstep", "One-Off Lockstep", 
                                                 "One Follows", "Matching-Bits Lockstep"))

data_equal$configuration <- factor(data_equal$configuration,
                                   labels = c("E1", "E2", "E3", "E4", "E5", "E6", "E7"))

data_equal$type <- factor(data_equal$type,
                          levels=c("beneficial", "deleterious", "neutral", "no_mutation"))

scenarios <- unique(data_equal$scenario)

data_equal$fraction_overall_ben_del_neu <- data_equal$fraction_overall_ben_del_neu*100  # to get percentage

for (sc in scenarios) {
  sc_data <- filter(data_equal, scenario == sc, type != "no_mutation")
  
  sc_data_ben <- filter(sc_data, type == "beneficial")
  sc_data_del <- filter(sc_data, type == "deleterious")
  sc_data_neu <- filter(sc_data, type == "neutral")
  
  summary_statistics_ben <- group_by(sc_data_ben, configuration, cell) %>%
    summarise(
      MeanW = paste(round(mean(value_overall), 2)),
      MeanF = paste(round(mean(fraction_overall_ben_del_neu), 2)),
      Count = n()
    )
  
  colnames(summary_statistics_ben)[3] <- "Ben."
  colnames(summary_statistics_ben)[4] <- "% Ben."
  
  summary_statistics_del <- group_by(sc_data_del, configuration, cell) %>%
    summarise(
      MeanW = paste(round(mean(value_overall), 2)),
      MeanF = paste(round(mean(fraction_overall_ben_del_neu), 2)),
      Count = n()
    )
  
  colnames(summary_statistics_del)[3] <- "Del."
  colnames(summary_statistics_del)[4] <- "% Del."
  
  summary_statistics_neu <- group_by(sc_data_neu, configuration, cell) %>%
    summarise(
      MeanW = paste(round(mean(value_overall), 2)),
      MeanF = paste(round(mean(fraction_overall_ben_del_neu), 2)),
      Count = n()
    )
  
  colnames(summary_statistics_neu)[3] <- "Neu."
  colnames(summary_statistics_neu)[4] <- "% Neu."
  
  summary_statistics <- merge(x = summary_statistics_ben, y = summary_statistics_del, by = c("configuration", "cell"))
  
  summary_statistics <- merge(x = summary_statistics, y = summary_statistics_neu, by = c("configuration", "cell"))
  
  # delete redundant "count"-columns
  summary_statistics$Count.x <- NULL
  summary_statistics$Count.y <- NULL

  colnames(summary_statistics)[1] <- "Config."
  colnames(summary_statistics)[2] <- "Cell"
  
  summary_statistics <- summary_statistics[,c(1,2,3,5,7,4,6,8,9)]
  
  print(xtable(summary_statistics,
               type = "latex",
               caption = paste("Summary statistics for mutation types in scenario ``", sc, "''. All values represent 
                               the mean values for beneficial, deleterious or neutral mutations. The values are provided 
                               as absolute numbers and as percentages.", sep = ""),
               label = paste("table:e_mutation_type_", sc, sep = ""),
               digits = c(0,0,0,2,2,2,2,2,2,0)),
        file = paste("mutation_type_", sc, ".tex", sep = ""),
        include.rownames=FALSE)
}
