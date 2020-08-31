library(xtable)
library(dplyr)
#library(flextable)

data_path_diff_fitness <- "../3_a_LocalMachineDataProcessing_Python/different_fitness_score.csv"
data_path_equal_fitness <- "../3_a_LocalMachineDataProcessing_Python/equal_fitness_score.csv"

data_diff <- read.csv(data_path_diff_fitness, na.strings = "NONE")
data_diff <- filter(data_diff, configuration != "DIFF_MUT_2", configuration != "DIFF_MUT_4")

data_equal <- read.csv(data_path_equal_fitness, na.strings = "NONE")
data_equal_3 <- filter(data_equal, configuration == "CONFIG_3")

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

data_equal_3$scenario <- factor(data_equal_3$scenario,
                              levels=c("noSelPressureBoth", "independentAddition",
                                       "lockstep", "oneOffLockstep", 
                                       "bFollowsA", "matchingBitsLockstep"),
                              labels = c("No Selection Pressure", "Additive Evolution",
                                         "Zero-Off Lockstep", "One-Off Lockstep", 
                                         "One Follows", "Matching-Bits Lockstep"))

data_diff$configuration <- factor(data_diff$configuration,
                                  levels = c("DIFF_MUT_1", "DIFF_MUT_3"),
                                  labels = c("D1", "D3"))

data_equal$configuration <- factor(data_equal$configuration,
                                   labels = c("E1", "E2", "E3", "E4", "E5", "E6", "E7"))

data_equal_3$configuration <- factor(data_equal_3$configuration,
                                   labels = c("E3"))

configurations_diff <- unique(data_diff$configuration)
configurations_equal <- unique(data_equal$configuration)


scenarios <- unique(data_equal$scenario)


for (sc in scenarios) {
  data_equal_1 <- filter(data_equal_3, scenario == sc)
  data_diff_1 <- filter(data_diff, scenario == sc, configuration == "D1")
  data_diff_2 <- filter(data_diff, scenario == sc, configuration == "D3")

  combined_data <- rbind(data_equal_1, data_diff_1, data_diff_2)

  summary_statistics <- group_by(combined_data, configuration, population_size, mutation_rate, cell) %>%
    summarise(
      Minimum = round(min(fitness_value_cell), 2),
      Median = round(median(fitness_value_cell), 2),
      Maximum = round(max(fitness_value_cell), 2),
      Mean = paste(round(mean(fitness_value_cell), 2)),
      Count = n()
    )

  colnames(summary_statistics)[1] <- "Config."
  colnames(summary_statistics)[2] <- "Pop. Size"
  colnames(summary_statistics)[3] <- "Mut. Rate"
  colnames(summary_statistics)[4] <- "Cell"
  colnames(summary_statistics)[5] <- "Min."
  colnames(summary_statistics)[7] <- "Max."
  colnames(summary_statistics)[8] <- "Mean"

  print(xtable(summary_statistics,
               type = "latex",
               caption = paste("Summary statistics for fitness scores in scenario ``", sc, "''.", sep = ""),
               label = paste("table:e_diff_fitness_", sc, sep = "")),
        file = paste("fitness_diff_", sc, ".tex", sep = ""),
        include.rownames=FALSE)
}

for (sc in scenarios) {
  sc_data <- filter(data_equal, scenario == sc)
  
  summary_statistics <- group_by(sc_data, configuration, population_size, mutation_rate, cell) %>%
    summarise(
      Minimum = round(min(fitness_value_cell), 2),
      Median = round(median(fitness_value_cell), 2),
      Maximum = round(max(fitness_value_cell), 2),
      Mean = paste(round(mean(fitness_value_cell), 2)),
      Count = n()
    )
  
  colnames(summary_statistics)[1] <- "Config."
  colnames(summary_statistics)[2] <- "Pop. Size"
  colnames(summary_statistics)[3] <- "Mut. Rate"
  colnames(summary_statistics)[4] <- "Cell"
  colnames(summary_statistics)[5] <- "Min."
  colnames(summary_statistics)[7] <- "Max."
  colnames(summary_statistics)[8] <- "Mean"
  
  print(xtable(summary_statistics, 
               type = "latex", 
               caption = paste("Summary statistics for fitness scores in scenario ``", sc, "''.", sep = ""),
               label = paste("table:e_equal_fitness_", sc, sep = ""),
               digits = c(0,0,0,3,0,2,2,2,2,0)), 
        file = paste("fitness_equal_", sc, ".tex", sep = ""), 
        include.rownames=FALSE)
}
