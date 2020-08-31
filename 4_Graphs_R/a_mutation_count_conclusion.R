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
          axis.text = element_text(size = 14),
          plot.title = element_text(size = 16))
  
  if (equal_or_diff == "e") {
    pl <- pl +
      #ggtitle(paste("Mutation Rate (MR): ", unique(data_var$mutation_rate), sep = "")) +
      ggtitle(paste("Configuration E3 (", unique(data_var$mutation_rate), "/", unique(data_var$mutation_rate), ")", sep = "")) +
      ylab("Mutation Count") +
      theme(axis.title.y = element_text(size = 15))
  } else if (equal_or_diff == "d") {
    pl <- pl +
      ggtitle(paste("Configuration D1 (", unique(filter(data_var, cell == "A")$mutation_rate), 
                    "/", unique(filter(data_var, cell == "B")$mutation_rate), ")", sep = "")) +
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

equal_mut_config <- "CONFIG_3"   # A&B mutation rate = 0.01
diff_mut_config <- "DIFF_MUT_1"   # A mutation rate = 0.01, B = 0.03

p_stripline_v <- ggplot() + geom_vline(xintercept = 50, size=2, color="grey85") + theme_void()


nsp_data_equal <- filter(data_equal,
                              scenario == "noSelPressureBoth",
                              configuration == equal_mut_config)
nsp_data_diff <- filter(data_diff,
                               scenario == "noSelPressureBoth",
                               configuration == diff_mut_config)

nsp_plot_equal <- plot.count(nsp_data_equal, nsp_data_equal$cell, 
                         nsp_data_equal$value_overall_ben_del_neu, "e")
nsp_plot_diff <- plot.count(nsp_data_diff, nsp_data_diff$cell, 
                        nsp_data_diff$value_overall_ben_del_neu, "d")

plot_complete_nsp <- grid.arrange(nsp_plot_equal, nsp_plot_diff, ncol = 2,
                                  top=textGrob("Scenario: No Selection Pressure", gp=gpar(fontsize=17, font=2)),
                                  bottom=textGrob("Cell Type", gp=gpar(fontsize=15)))


zol_data_equal <- filter(data_equal,
                              scenario == "lockstep",
                              configuration == equal_mut_config)
zol_data_diff <- filter(data_diff,
                             scenario == "lockstep",
                             configuration == diff_mut_config)

zol_plot_equal <- plot.count(zol_data_equal, zol_data_equal$cell, 
                             zol_data_equal$value_overall_ben_del_neu, "e")
zol_plot_diff <- plot.count(zol_data_diff, zol_data_diff$cell, 
                            zol_data_diff$value_overall_ben_del_neu, "d")

plot_complete_zol <- grid.arrange(zol_plot_equal, zol_plot_diff, ncol = 2,
                              top=textGrob("Scenario: Zero-Off Lockstep", gp=gpar(fontsize=17, font=2)),
                              bottom=textGrob("Cell Type", gp=gpar(fontsize=15)))


plot_complete <- grid.arrange(plot_complete_nsp, p_stripline_v, plot_complete_zol, ncol = 3, widths = c(6,1,6))

ggsave(file="./a_mutation_count/mutation_count_conclusion.png", plot_complete, width = 16, height = 5)