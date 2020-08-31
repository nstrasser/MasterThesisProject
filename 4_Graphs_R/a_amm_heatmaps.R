library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(plotly)
library(grid)
library(gridExtra)


plot.heatmap <- function(data_var, config_var) {
  current_mutation_rate <- unique(data_var$mutation_rate_a)
  current_population_size <- unique(data_var$population_size)
  
  pl <- ggplot(data = data_var, aes(x=a_replicate, y=b_replicate, fill=variance_overall)) +
    geom_tile() +
    scale_fill_gradient(low = "red", high = "white") +
    theme(plot.title = element_text(size = 18), 
          plot.subtitle = element_text(size = 18),
          axis.title = element_blank(),
          axis.text = element_text(size=16),
          axis.text.x = element_text(angle = 90, hjust = 1),
          legend.text = element_text(size=16),
          legend.title = element_text(size=16)) + 
    labs(fill="AMM", subtitle = paste("Mutation Rate: ", current_mutation_rate, "\nPopulation Size: ", current_population_size, sep = ""))
  
  return(pl)
}

data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_amm_heatmaps.csv"

data <- read.csv(data_path, na.strings="NONE")

data$configuration <- factor(data$configuration, levels=c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7"))
theme_set(theme_cowplot())


scenarios <- c("lockstep",
               "oneOffLockstep",
               "bFollowsA",
               "independentAddition",
               "noSelPressureBoth",
               "matchingBitsLockstep")

configs <- c("CONFIG_1", "CONFIG_2", "CONFIG_3", 
             "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7")

for (sc in scenarios) {
  if (sc == 'lockstep') { heading <- "Zero-Off Lockstep" }
  else if (sc == 'oneOffLockstep') { heading <- "One-Off Lockstep" }
  else if (sc == 'bFollowsA') { heading <- "One Follows" }
  else if (sc == 'independentAddition') { heading <- "Additive Evolution" }
  else if (sc == 'noSelPressureBoth') { heading <- "No Selection Pressure" }
  else if (sc == 'matchingBitsLockstep') { heading <- "Matching-Bits Lockstep" }
  
  data_c1 <- filter(data, scenario==sc, configuration=="CONFIG_1")
  data_c2 <- filter(data, scenario==sc, configuration=="CONFIG_2")
  data_c3 <- filter(data, scenario==sc, configuration=="CONFIG_3")
  data_c4 <- filter(data, scenario==sc, configuration=="CONFIG_4")
  data_c5 <- filter(data, scenario==sc, configuration=="CONFIG_5")
  data_c6 <- filter(data, scenario==sc, configuration=="CONFIG_6")
  data_c7 <- filter(data, scenario==sc, configuration=="CONFIG_7")
  
  pl_c1 <- plot.heatmap(data_c1)
  pl_c2 <- plot.heatmap(data_c2)
  pl_c3 <- plot.heatmap(data_c3)
  pl_c4 <- plot.heatmap(data_c4)
  pl_c5 <- plot.heatmap(data_c5)
  pl_c6 <- plot.heatmap(data_c6)
  pl_c7 <- plot.heatmap(data_c7)
  
  plot_complete <- grid.arrange(pl_c1, pl_c2, pl_c3, pl_c4, pl_c5, pl_c6, pl_c7, nrow = 2,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=20, font=2)),
                                bottom=textGrob("A-Cell (Seed)", gp=gpar(fontsize=18)),
                                left=textGrob("B-Cell (Seed)", gp=gpar(fontsize=18), rot = 90))

  ggsave(file=paste("./a_amm/heatmaps/amm_heatmaps_", sc, ".png", sep = ""), plot_complete, width = 16, height = 8)
}