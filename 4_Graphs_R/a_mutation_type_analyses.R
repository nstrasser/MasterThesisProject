library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(grid)
library(gridExtra)

plot.type <- function(data_var, aes_x_col_var, aes_y_var, percent_or_whole, mut_or_pop) {
  pl <- ggplot(data=filter(data_var),
               aes(x = aes_x_col_var, y = aes_y_var, color = aes_x_col_var)) +
    geom_boxplot() +
    geom_jitter(alpha = 0.7) +
    scale_color_manual(values = temp) +
    theme(legend.position = "none", axis.text.x = element_text(angle = 90, hjust = 1),
          axis.text = element_text(size = 14),
          axis.title = element_blank(),
          strip.text.x = element_text(size = 14),
          strip.text.y = element_text(size = 14))
  
  if (percent_or_whole == "percent") {
    pl <- pl +
      scale_y_continuous(limits = c(0,100))
  } else if (percent_or_whole == "whole") {
    pl <- pl +
      scale_y_continuous(limits = c(0,2100))
  } else {
    print("Error in function plot.type!")
  }
  
  if (mut_or_pop == "mut") {
    pl <- pl +
      facet_grid(rows=vars(mutation_rate), cols=vars(population_size))
  } else if (mut_or_pop == "pop") {
    pl <- pl +
      facet_grid(rows=vars(population_size), cols=vars(mutation_rate))
  } else {
    print("Error in function plot.type!")
  }
  
  return(pl)
}


data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_mutation_type.csv"
data <- read.csv(data_path, na.strings="NONE")

data$population_size <- factor(data$population_size, 
                               levels=c(10,100,1000,10000))
data$mutation_rate <- factor(data$mutation_rate,
                             levels=c(0.001,0.003,0.01,0.03))
data$configuration <- factor(data$configuration,
                             levels=c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7"))
data$type <- factor(data$type,
                    levels=c("beneficial", "deleterious", "neutral", "no_mutation"))
data$fraction_overall_ben_del_neu <- data$fraction_overall_ben_del_neu*100  # to get percentage

theme_set(theme_bw())

temp <- c("#33A02C", "#B2182B", "#666666")

scenarios <- c("lockstep",
               "oneOffLockstep",
               "bFollowsA",
               "independentAddition",
               "noSelPressureBoth",
               "matchingBitsLockstep")


for (sc in scenarios) {
  if (sc == 'lockstep') { heading <- "Zero-Off Lockstep" }
  else if (sc == 'oneOffLockstep') { heading <- "One-Off Lockstep" }
  else if (sc == 'bFollowsA') { heading <- "One Follows" }
  else if (sc == 'independentAddition') { heading <- "Additive Evolution" }
  else if (sc == 'noSelPressureBoth') { heading <- "No Selection Pressure" }
  else if (sc == 'matchingBitsLockstep') { heading <- "Matching-Bits Lockstep" }
  
  scenario_data_mutation <- filter(data, scenario==sc, mutation_rate==0.01, type!="no_mutation")
  scenario_data_population <- filter(data, scenario==sc, population_size==1000, type!="no_mutation")
  
  # for whole numbers
  mutation_plot_whole <- plot.type(scenario_data_mutation, scenario_data_mutation$type, 
                                       scenario_data_mutation$value_overall, "whole", "mut")
  population_plot_whole <- plot.type(scenario_data_population, scenario_data_population$type, 
                                        scenario_data_population$value_overall, "whole", "pop")
  
  plot_complete <- grid.arrange(population_plot_whole, mutation_plot_whole, nrow = 2,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=16, font=2)),
                                bottom=textGrob("Mutation Type", gp=gpar(fontsize=15)),
                                left=textGrob("Mutation Count", gp=gpar(fontsize=15), rot = 90))

  ggsave(file=paste("./a_mutation_type/mutation_type_whole_", sc, ".png", sep = ""), plot_complete, width = 12, height = 9)
  
  # for percent
  mutation_plot_percent <- plot.type(scenario_data_mutation, scenario_data_mutation$type, 
                                   scenario_data_mutation$fraction_overall_ben_del_neu, "percent", "mut")
  population_plot_percent <- plot.type(scenario_data_population, scenario_data_population$type, 
                                     scenario_data_population$fraction_overall_ben_del_neu, "percent", "pop")
  
  plot_complete <- grid.arrange(population_plot_percent, mutation_plot_percent, nrow = 2,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=16, font=2)),
                                bottom=textGrob("Mutation Type", gp=gpar(fontsize=15)),
                                left=textGrob("Percentage", gp=gpar(fontsize=15), rot = 90))
  
  ggsave(file=paste("./a_mutation_type/mutation_type_percent_", sc, ".png", sep = ""), plot_complete, width = 12, height = 8.5)
}