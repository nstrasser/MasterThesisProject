library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(RColorBrewer)
library(grid)
library(gridExtra)


plot.boxplot <- function(data_var, aes_x_col_var, aes_y_var, scenario) {
  pl <- ggplot(data = data_var,
               aes(x = aes_x_col_var, y = aes_y_var, color = aes_x_col_var)) +
    geom_boxplot() +
    geom_jitter(alpha = 0.7) +
    scale_color_manual(values = colors) +
    scale_y_continuous(limits = c(0,51)) +
    xlab("Comparison Type") +
    ylab("AMM") +
    ggtitle(scenario) +
    theme(legend.position = "none",
          axis.text = element_text(size = 18),
          axis.title = element_text(size = 19),
          plot.title = element_text(size = 21, face = "bold", hjust = 0.5))
  
  return(pl)
}


data_path <- "../3_a_LocalMachineDataProcessing_Python/equal_amm.csv"
data <- read.csv(data_path, na.strings="NONE")

theme_set(theme_bw())

colors <- c("#7A0177", "#DD3497")

data$comparison <- factor(data$comparison, levels = c("intra-run", "inter-run"))

p_stripline_v <- ggplot() + geom_vline(xintercept = 50, size=2, color="grey85") + theme_void()


nsp_data <- filter(data, scenario=="noSelPressureBoth", mutation_rate_a==0.01, population_size==1000, comparison != "inter-treatment")

nsp_plot <- plot.boxplot(nsp_data, nsp_data$comparison, 
                         nsp_data$variance_overall, "No Selection Pressure")


zol_data <- filter(data, scenario=="lockstep", mutation_rate_a==0.01, population_size==1000, comparison != "inter-treatment")

zol_plot <- plot.boxplot(zol_data, zol_data$comparison, 
                           zol_data$variance_overall, "Zero-Off Lockstep")

plot_complete <- grid.arrange(nsp_plot, p_stripline_v, zol_plot, ncol = 3, widths = c(6,1,6))
ggsave(file=paste("./a_amm/boxplots/amm_boxplots_conclusion.png", sep = ""), plot_complete, width = 16, height = 9)