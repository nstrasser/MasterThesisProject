library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(RColorBrewer)
library(grid)
library(gridExtra)


plot.boxplot <- function(data_var, aes_x_col_var, aes_y_var, mut_or_pop) {
  pl <- ggplot(data=filter(data_var),
               aes(x = aes_x_col_var, y = aes_y_var, color = aes_x_col_var)) +
    geom_boxplot() +
    geom_jitter(alpha = 0.7) +
    scale_color_manual(values = colors) +
    theme(legend.position = "none", axis.text.x = element_text(angle = 90, hjust = 1),
          axis.text = element_text(size = 14),
          axis.title = element_blank(),
          strip.text.x = element_text(size = 14),
          strip.text.y = element_text(size = 14))
  
  if (mut_or_pop == "mut") {
    pl <- pl +
      facet_grid(rows=vars(mutation_rate_a), cols=vars(population_size))
  } else if (mut_or_pop == "pop") {
    pl <- pl +
      facet_grid(rows=vars(population_size), cols=vars(mutation_rate_a))
  } else {
    print("Error in function plot.type!")
  }
  
  return(pl)
}


data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_amm.csv"
data <- read.csv(data_path, na.strings="NONE")

data$population_size <- factor(data$population_size, 
                               levels=c(10,100,1000,10000))
data$mutation_rate_a <- factor(data$mutation_rate_a,
                               levels=c(0.001,0.003,0.01,0.03))

data$comparison <- factor(data$comparison, levels=c("intra-run", "inter-run", "inter-treatment"))
data$configuration <- factor(data$configuration, levels=c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7"))
data$scenario <- factor(data$scenario, levels=c("noSelPressureBoth", "lockstep", "oneOffLockstep", "independentAddition", "bFollowsA", "matchingBitsLockstep"))

theme_set(theme_bw())

scenarios <- c("lockstep",
               "oneOffLockstep",
               "bFollowsA",
               "independentAddition",
               "noSelPressureBoth",
               "matchingBitsLockstep")
colors <- c("#7A0177", "#DD3497", "#F768A1")


for (sc in scenarios) {
  if (sc == 'lockstep') { heading <- "Zero-Off Lockstep" }
  else if (sc == 'oneOffLockstep') { heading <- "One-Off Lockstep" }
  else if (sc == 'bFollowsA') { heading <- "One Follows" }
  else if (sc == 'independentAddition') { heading <- "Additive Evolution" }
  else if (sc == 'noSelPressureBoth') { heading <- "No Selection Pressure" }
  else if (sc == 'matchingBitsLockstep') { heading <- "Matching-Bits Lockstep" }
  
  scenario_data_mutation <- filter(data, scenario==sc, mutation_rate_a==0.01)
  scenario_data_population <- filter(data, scenario==sc, population_size==1000)
  
  mutation_plot_whole <- plot.boxplot(scenario_data_mutation, scenario_data_mutation$comparison, 
                                   scenario_data_mutation$variance_overall, "mut")
  population_plot_whole <- plot.boxplot(scenario_data_population, scenario_data_population$comparison, 
                                     scenario_data_population$variance_overall, "pop")
  
  plot_complete <- grid.arrange(population_plot_whole, mutation_plot_whole, nrow = 2,
                                top=textGrob(paste("Scenario: ", heading, sep = ""), gp=gpar(fontsize=16, font=2)),
                                bottom=textGrob("Comparison Type", gp=gpar(fontsize=15)),
                                left=textGrob("AMM", gp=gpar(fontsize=15), rot = 90))
  
  ggsave(file=paste("./a_amm/boxplots/amm_boxplots_", sc, ".png", sep = ""), plot_complete, width = 12, height = 9)
}

##########################################################################################################################
# Statistical Tests
##########################################################################################################################
print("START STATISTICAL TESTS")
scenarios <- c("noSelPressureBoth", "lockstep", "oneOffLockstep", "independentAddition", "bFollowsA", "matchingBitsLockstep")
configs <- c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7")

for (sc in scenarios) {
  scenario_data <- filter(data, scenario==sc)
  for (config in configs) {
    print(paste(config, ": ", sc, sep = ""))
    test_data <- filter(scenario_data, configuration==config)
    kt <- kruskal.test(formula=variance_overall ~ comparison, data=test_data)
    print(kt)
    
    if (kt$p.value <= 0.05) {
      wt <- pairwise.wilcox.test(x=test_data$variance_overall, 
                                 g=test_data$comparison,
                                 p.adjust.method="bonferroni")
      print(wt)  
    }
  }
}

##########################################################################################################################
# Mean/Median
##########################################################################################################################
print("START MEAN/MEDIAN")
unique_combinations <- unique(data[,c('configuration', 'scenario', 'comparison')])

# transpose the data frame
unique_combinations <- t(unique_combinations)
unique_combinations <- as.data.frame(unique_combinations)

df <- data.frame(matrix(ncol = 6, nrow = 0))
x <- c("scenario", "comparison", "population_size", "mutation_rate", "mean", "median")
colnames(df) <- x

for (combi in unique_combinations) {
  filtered_data = filter(data, configuration==combi[1], scenario==combi[2], comparison==combi[3])
  filtered_mean <- mean(filtered_data$variance_overall)
  filtered_median <- median(filtered_data$variance_overall)
  
  curr_df <- data.frame("scenario" = combi[2],
                        "comparison" = combi[3], 
                        "population_size" = unique(filtered_data$population_size), 
                        "mutation_rate" = unique(filtered_data$mutation_rate_a), 
                        "mean" = round(filtered_mean, digits = 2), 
                        "median" = round(filtered_median, digits = 2))
  
  df <- rbind(df, curr_df)
}

print(df)