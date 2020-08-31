library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(grid)
library(gridExtra)


plot.count <- function(data_var, aes_x_col_var, aes_y_var, equal_or_diff) {
  pl <- ggplot(data = data_var,
                  aes(x = aes_x_col_var, y = aes_y_var, color = aes_x_col_var)) +
    geom_boxplot() +
    geom_jitter(alpha = 0.7) +
    scale_color_manual(values = temp) +
    scale_y_continuous(limits = c(0,5100), breaks = c(0,1000,2000,3000,4000,5000)) +
    theme(legend.position = "none",
          axis.title.x = element_blank(),
          axis.text = element_text(size = 13),
          plot.title = element_text(size = 14))
  
  if (equal_or_diff == "e") {
    pl <- pl +
      #ggtitle(paste("Mutation Rate (MR): ", unique(data_var$mutation_rate), sep = "")) +
      ggtitle(paste("Configuration E3 (", unique(data_var$mutation_rate), "/", unique(data_var$mutation_rate), ")", sep = "")) +
      ylab("Mutation Count") +
      theme(axis.title.y = element_text(size = 14))
  } else if (equal_or_diff == "d1") {
    pl <- pl +
      ggtitle(paste("Configuration D1 (", unique(filter(data_var, cell == "A")$mutation_rate), 
                    "/", unique(filter(data_var, cell == "B")$mutation_rate), ")", sep = "")) +
      theme(axis.title.y=element_blank())
  } else if (equal_or_diff == "d2") {
    pl <- pl +
      ggtitle(paste("Configuration D3 (", unique(filter(data_var, cell == "A")$mutation_rate), 
                    "/", unique(filter(data_var, cell == "B")$mutation_rate),")", sep = "")) +
      theme(axis.title.y=element_blank())
  } else {
    print("Error in function plot.count!")
  }
  
  return(pl)
}


data_path_equal <- "../3_a_LocalMachineDataProcessing_Python/equal_mutation_count.csv"
data_path_diff <- "../3_a_LocalMachineDataProcessing_Python/different_mutation_count.csv"

data_equal <- read.csv(data_path_equal, na.strings = "NONE")
data_diff <- read.csv(data_path_diff, na.strings = "NONE")

theme_set(theme_bw())

temp <- c("#053061", "#FFD92F")

scenarios <- c("lockstep",
              "oneOffLockstep",
              "bFollowsA",
              "independentAddition",
              "noSelPressureBoth",
              "matchingBitsLockstep")

equal_mut_config <- "CONFIG_3"   # A&B mutation rate = 0.01
diff_mut_config_1 <- "DIFF_MUT_1"   # A mutation rate = 0.01, B = 0.03
diff_mut_config_2 <- "DIFF_MUT_3"   # A mutation rate = 0.01, B = 0.1


for (sc in scenarios) {
  if (sc == 'lockstep') { heading <- "Zero-Off Lockstep" }
  else if (sc == 'oneOffLockstep') { heading <- "One-Off Lockstep" }
  else if (sc == 'bFollowsA') { heading <- "One Follows" }
  else if (sc == 'independentAddition') { heading <- "Additive Evolution" }
  else if (sc == 'noSelPressureBoth') { heading <- "No Selection Pressure" }
  else if (sc == 'matchingBitsLockstep') { heading <- "Matching-Bits Lockstep" }
  
  scenario_data_equal <- filter(data_equal,
                                scenario == sc,
                                configuration == equal_mut_config)
  scenario_data_diff_1 <- filter(data_diff,
                                scenario == sc,
                                configuration == diff_mut_config_1)
  scenario_data_diff_2 <- filter(data_diff,
                                 scenario == sc,
                                 configuration == diff_mut_config_2)
  
  plot_equal <- plot.count(scenario_data_equal, scenario_data_equal$cell, 
                             scenario_data_equal$value_overall_ben_del_neu, "e")
  plot_diff_1 <- plot.count(scenario_data_diff_1, scenario_data_diff_1$cell, 
                              scenario_data_diff_1$value_overall_ben_del_neu, "d1")
  plot_diff_2 <- plot.count(scenario_data_diff_2, scenario_data_diff_2$cell, 
                              scenario_data_diff_2$value_overall_ben_del_neu, "d2")
  
  plot_complete <- grid.arrange(plot_equal, plot_diff_1, plot_diff_2, ncol = 3,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=15, font=2)),
                                bottom=textGrob("Cell Type", gp=gpar(fontsize=14)))
  
  ggsave(file=paste("./a_mutation_count/mutation_count_", sc, ".png", sep = ""), plot_complete, width = 12, height = 5)
}