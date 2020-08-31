library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(RColorBrewer)
library(grid)
library(gridExtra)


draw.facets <- function(data_var, aes_y_var, is_what) {
  pl <- ggplot(data = data_var,
            aes(x = update, y = aes_y_var, colour = bin, fill = bin)) +
    geom_area() +
    scale_color_manual(values = colors, aesthetics = c("colour", "fill")) +
    scale_x_continuous(breaks = c(0,2500,5000)) +
    scale_y_continuous(breaks = c(0,500,1000)) +
    xlab("Generation") +
    ylab("Count of Individuals with Score") +
    facet_wrap(~ replicate) +
    theme(legend.position = "none",
          axis.title = element_text(size = 18),
          axis.text = element_text(size = 16),
          plot.title = element_text(size = 18, face = "bold"),
          strip.text = element_text(size = 16),
          panel.spacing = unit(1.5, "lines"),
          panel.grid = element_blank(),
          panel.background = element_rect(fill = "grey85", colour = NA))
  
  if (is_what == "org") {
    pl <- pl +
      theme(legend.position = "bottom",
            legend.text = element_text(size=18),
            legend.title = element_text(size=18)) +
      guides(colour = guide_legend(title = "Fitness Score",
                                        title.position = "top", 
                                        title.hjust = 0.5),
             fill = guide_legend(title = "Fitness Score",
                                   title.position = "top", 
                                   title.hjust = 0.5)) +
      ggtitle("Organism")
  }
  
  if (is_what == "a") {
    pl <- pl +
      ggtitle("A-Cell")
  }
    
  if (is_what == "b") {
    pl <- pl +
      ggtitle("B-Cell")
  }
  
  return(pl)
}


data_path <- "../2_FromHPCC/b_Migration/migration_facet_snapshots.csv"
data <- read.csv(data_path, na.strings="NONE")

data$migration_rate <- factor(data$migration_rate, 
                               levels=c(0,10,20,30,40,50,60,70,80,90,100))
data$bin <- factor(data$bin, levels=c("0-20", "20-40", "40-60", "60-80", "80-100"))

theme_set(theme_bw())

colors <- c("#673F03", "#B50142", "#AB08FF", "#4755FF", "#B2FCE3")
migration_rates <- c(0,10,20,30,40,50,60,70,80,90,100)


for (mr in migration_rates) {
  mr_data = filter(data, migration_rate==mr)

  # plot and save
  plot_a <- draw.facets(mr_data, mr_data$a_count, "a")
  plot_b <- draw.facets(mr_data, mr_data$b_count, "b")
  plot_org <- draw.facets(mr_data, mr_data$org_count, "org")
  
  # combine and annotate plots with generation number
  combined <- cowplot::plot_grid(plot_a, plot_b, plot_org,
                                 ncol = 1,
                                 nrow = 3,
                                 rel_heights = c(1,1,1.15))
  
  # add title
  plot_complete <- grid.arrange(combined,
                                top=textGrob(paste("Migration Rate: ", mr, "%\n", sep = ""), gp=gpar(fontsize=20, font=2)))
  
  # save 
  ggsave(paste("./b_facets/facet_mr_", mr, ".png", sep = ""), plot_complete, width = 12, height = 20)
}