library(xtable)
library(dplyr)

data_path_diff_fitness <- "../3_a_LocalMachineDataProcessing_Python/different_mutation_count.csv"
data_path_equal_fitness <- "../3_a_LocalMachineDataProcessing_Python/equal_mutation_count.csv"

data_diff <- read.csv(data_path_diff_fitness, na.strings = "NONE")
data_equal <- read.csv(data_path_equal_fitness, na.strings = "NONE")

data_diff <- filter(data_diff, configuration != "DIFF_MUT_2", configuration != "DIFF_MUT_4")
data_equal <- filter(data_equal, configuration == "CONFIG_3")

data_diff$scenario <- factor(data_diff$scenario,
                             levels=c("noSelPressureBoth", "independentAddition",
                                      "lockstep", "oneOffLockstep", 
                                      "bFollowsA", "matchingBitsLockstep"),
                             labels = c("No Selection Pressure", "Additive Evolution", 
                                        "Zero-Off Lockstep", "One-Off Lockstep", 
                                        "One Follows", "Matching-Bits Lockstep"))

data_equal$scenario <- factor(data_equal$scenario,
                              levels=c("noSelPressureBoth", "independentAddition",
                                       "lockstep", "oneOffLockstep", 
                                       "bFollowsA", "matchingBitsLockstep"),
                              labels = c("No Selection Pressure", "Additive Evolution",
                                         "Zero-Off Lockstep", "One-Off Lockstep", 
                                         "One Follows", "Matching-Bits Lockstep"))

data_diff$configuration <- factor(data_diff$configuration,
                                  levels = c("DIFF_MUT_1", "DIFF_MUT_3"),
                                  labels = c("D1", "D3"))

data_equal$configuration <- factor(data_equal_3$configuration,
                                     labels = c("E3"))

scenarios <- unique(data_equal$scenario)


for (sc in scenarios) {
  data_equal_1 <- filter(data_equal, scenario == sc)
  data_diff_1 <- filter(data_diff, scenario == sc, configuration == "D1")
  data_diff_2 <- filter(data_diff, scenario == sc, configuration == "D3")
  
  combined_data <- rbind(data_equal_1, data_diff_1, data_diff_2)

  summary_statistics <- group_by(combined_data, configuration, population_size, mutation_rate, cell) %>%
    summarise(
      #Minimum = round(min(value_overall_ben_del_neu), 2),
      #Median = round(median(value_overall_ben_del_neu), 2),
      #Maximum = round(max(value_overall_ben_del_neu), 2),
      Mean = paste(round(mean(value_overall_ben_del_neu), 2)),
      Count = n()
    )
  
  colnames(summary_statistics)[1] <- "Configuration"
  colnames(summary_statistics)[2] <- "Pop. Size"
  colnames(summary_statistics)[3] <- "Mut. Rate"
  colnames(summary_statistics)[4] <- "Cell"
  colnames(summary_statistics)[5] <- "Mean"
  
  #print(summary_statistics)
  
  print(xtable(summary_statistics,
               type = "latex",
               caption = paste("Mean values for mutation counts in scenario ``", sc, "''.", sep = ""),
               label = paste("table:e_mutation_count_", sc, sep = "")),
        file = paste("mutation_count_", sc, ".tex", sep = ""),
        include.rownames=FALSE)
}
