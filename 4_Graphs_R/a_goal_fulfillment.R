library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(grid)
library(gridExtra)


plot.fitness <- function(data_var, aes_x_col_var, aes_y_var, mbl_or_other, mut_or_pop) {
  pl <- ggplot(data = data_var,
               aes(x = aes_x_col_var, y = aes_y_var, color = aes_x_col_var)) +
    geom_boxplot() +
    geom_jitter(alpha = 0.7) +
    scale_color_manual(values = colors) +
    theme(legend.position = "none",
          axis.text = element_text(size = 14),
          axis.title = element_blank(),
          strip.text.x = element_text(size = 14),
          strip.text.y = element_text(size = 14))

  if (mbl_or_other == "other") {
    pl <- pl +
      scale_y_continuous(limits = c(-10,101)) # start at -10 because negative fitness values are possible; highest possible is 100
  } else if (mbl_or_other == "mbl") {
    pl <- pl +
      scale_y_continuous(limits = c(-10,1201)) # start at -10 because negative fitness values are possible; highest possible is 1200
  } else {
    print("Error in function plot.fitness!")
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


data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_fitness_score.csv"
data <- read.csv(data_path, na.strings = "NONE")

data$population_size <- factor(data$population_size, 
                               levels=c(10,100,1000,10000))
data$mutation_rate <- factor(data$mutation_rate,
                             levels=c(0.001,0.003,0.01,0.03))
data$configuration <- factor(data$configuration,
                             levels=c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7"))

theme_set(theme_bw())

colors <- c("#660000ff", "#FDE725FF", "turquoise3")

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

  scenario_data_mutation <- filter(data, scenario==sc, mutation_rate==0.01)
  scenario_data_population <- filter(data, scenario==sc, population_size==1000)
  
  if (sc == "matchingBitsLockstep") {
    mutation_plot <- plot.fitness(scenario_data_mutation, scenario_data_mutation$cell, 
                                     scenario_data_mutation$fitness_value_cell, "mbl", "mut")
    population_plot <- plot.fitness(scenario_data_population, scenario_data_population$cell, 
                                       scenario_data_population$fitness_value_cell, "mbl", "pop")
  } else {
    mutation_plot <- plot.fitness(scenario_data_mutation, scenario_data_mutation$cell, 
                                  scenario_data_mutation$fitness_value_cell, "other", "mut")
    population_plot <- plot.fitness(scenario_data_population, scenario_data_population$cell, 
                                    scenario_data_population$fitness_value_cell, "other", "pop")
  }
  
  plot_complete <- grid.arrange(mutation_plot, population_plot, nrow = 2,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=16, font=2)),
                                bottom=textGrob("Cell Type", gp=gpar(fontsize=15)),
                                left=textGrob("Fitness Score", gp=gpar(fontsize=15), rot = 90))
  
  ggsave(file=paste("./a_goal_fulfillment/goal_fulfillment_", sc, ".png", sep = ""), plot_complete, width = 12, height = 10)

}