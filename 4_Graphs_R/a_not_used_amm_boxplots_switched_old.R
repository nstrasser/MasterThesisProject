library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)

data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_amm_switched_pairs.csv"

data <- read.csv(data_path, na.strings="NONE")

data$population_size <- factor(data$population_size, 
                               levels=c(10,100,1000,10000))
data$mutation_rate_a <- factor(data$mutation_rate_a,
                               levels=c(0.001,0.003,0.01,0.03))

data$comparison <- factor(data$comparison, levels=c("intra-run", "inter-run", "inter-treatment"))
data$configuration <- factor(data$configuration, levels=c("CONFIG_1", "CONFIG_2", "CONFIG_3", "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7"))
data$scenario <- factor(data$scenario, levels=c("noSelPressureBoth", "lockstep", "oneOffLockstep", "independentAddition", "bFollowsA", "matchingBitsLockstep"))

theme_set(theme_bw())


scenario_names <- c(`noSelPressureBoth` = "No Selection Pressure",
                    `lockstep` = "Zero-Off Lockstep",
                    `oneOffLockstep` = "One-Off Lockstep",
                    `bFollowsA` = "One Follows",
                    `independentAddition` = "Additive Evolution",
                    `matchingBitsLockstep` = "Matching-Bits Lockstep")

configs <- c("CONFIG_1", "CONFIG_2", "CONFIG_3", 
             "CONFIG_4", "CONFIG_5", "CONFIG_6", "CONFIG_7")

colors <- c("#7A0177", "#DD3497", "#F768A1")



for (config in configs) {
  if (config == 'CONFIG_1') { heading <- "Configuration 1" }
  else if (config == 'CONFIG_2') { heading <- "Configuration 2" }
  else if (config == 'CONFIG_3') { heading <- "Configuration 3" }
  else if (config == 'CONFIG_4') { heading <- "Configuration 4" }
  else if (config == 'CONFIG_5') { heading <- "Configuration 5" }
  else if (config == 'CONFIG_6') { heading <- "Configuration 6" }
  else if (config == 'CONFIG_7') { heading <- "Configuration 7" }
  
  
  config_data = filter(data, configuration==config, scenario!='bFollowsA', scenario!='independentAddition', 
                       scenario!='matchingBitsLockstep') 
  
  pl <- ggplot(data=config_data, 
                           aes(x=comparison, y=variance_overall, color=comparison)) +
    geom_boxplot() +
    geom_jitter(alpha=0.7) +
    scale_color_manual(values = colors) +
    facet_grid(cols=vars(scenario), labeller = as_labeller(scenario_names)) +
    xlab("Comparison Type") +
    ylab("Accumulated Mutations Metric (AMM)") +
    ggtitle(paste(heading, " (Population Size: ", config_data$population_size, ", Mutation Rate: ", config_data$mutation_rate_a, ")", sep = "")) +
    theme(legend.position = "none",
          plot.title = element_text(size = 21), 
          axis.text = element_text(size = 17),
          axis.title = element_text(size=19),
          strip.text.x = element_text(size = 17)) +
    ggsave(paste("./a_amm/boxplots_switched/amm_boxplots_locksteps_", config, ".png", sep = ""), width = 18)
}

for (config in configs) {
  if (config == 'CONFIG_1') { heading <- "Configuration 1" }
  else if (config == 'CONFIG_2') { heading <- "Configuration 2" }
  else if (config == 'CONFIG_3') { heading <- "Configuration 3" }
  else if (config == 'CONFIG_4') { heading <- "Configuration 4" }
  else if (config == 'CONFIG_5') { heading <- "Configuration 5" }
  else if (config == 'CONFIG_6') { heading <- "Configuration 6" }
  else if (config == 'CONFIG_7') { heading <- "Configuration 7" }
  
  config_data = filter(data, configuration==config, scenario!='lockstep', scenario!='oneOffLockstep') 
  
  pl <- ggplot(data=config_data, 
               aes(x=comparison, y=variance_overall, color=comparison)) +
    geom_boxplot() +
    geom_jitter(alpha=0.7) +
    scale_color_manual(values = colors) +
    facet_grid(cols=vars(scenario), labeller = as_labeller(scenario_names)) +
    xlab("Comparison Type") +
    ylab("Accumulated Mutations Metric (AMM)") +
    ggtitle(paste(heading, " (Population Size: ", config_data$population_size, ", Mutation Rate: ", config_data$mutation_rate_a, ")", sep = "")) +
    theme(legend.position = "none",
          plot.title = element_text(size = 21), 
          axis.text = element_text(size = 17),
          axis.title = element_text(size=19),
          strip.text.x = element_text(size = 17)) +
    ggsave(paste("./a_amm/boxplots_switched/amm_boxplots_others_", config, ".png", sep = ""), width = 18)
}

##########################################################################################################################
# Statistical Tests
##########################################################################################################################
print("START STATISTICAL TESTS")
scenarios <- c("noSelPressureBoth", "lockstep", "oneOffLockstep", "independentAddition", "bFollowsA", "matchingBitsLockstep")

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