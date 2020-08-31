library(ggplot2)  # (Wickham, 2016)
library(tidyr)    # (Wickham and Henry, 2020)
library(dplyr)    # (Wickham et al., 2020)
library(cowplot)  # (Wilke, 2019)
library(grid)
library(gridExtra)
library(egg)


##############################################################################################################################
##############################################        FUNCTIONS        #######################################################
##############################################################################################################################

# set up main scatter plot
draw.scatter <- function(data_var, aes_x_var, aes_y_var, aes_colour_var, migrated_or_score, current_generation) {
  scatter <- ggplot(data = data_var,
               aes(x = aes_x_var, 
                   y = aes_y_var)) +
    geom_point(aes(colour = aes_colour_var),
               size = 2,
               alpha = 1.0) +   # no alpha (transparency) since it is bad for b/w-print
    scale_x_continuous(limits = c(0,100)) +
    scale_y_continuous(limits = c(0,100)) +
    xlab("A-Cell Fitness") +
    ylab("B-Cell Fitness") +
    theme(plot.margin = margin(),
          legend.position = "none",
          axis.title = element_text(size = 18),
          axis.text = element_text(size = 16))
  
  if (migrated_or_score == "m") {
    scatter <- scatter +
      scale_colour_manual(name = "Migrated?",
                          values = colors,
                          drop = FALSE) + # always show all values in legend; works in combination with "migrated"-factor-definition
      guides(colour = guide_legend(title.position = "top", 
                                   title.hjust = 0.7)) # place title of legend in the middle
  } else if (migrated_or_score == "s") {
    scatter <- scatter +
      scale_color_viridis_c(name = "Organism Fitness", 
                            option = "A", 
                            limits = c(0,100),
                            breaks = c(0,50,100)) + # magma with guide limits always from 0 to 100 (for comparability across plots)
    guides(colour = guide_colourbar(title.position = "left",
                                    title.vjust = 1.0)) # place title of legend in the middle
  } else {
    print("Error in function draw.scatter!")
  }
  
  if (current_generation == 5000) {
    scatter <- scatter +
      theme(plot.margin = margin(),
            legend.position = "bottom",
            legend.text = element_text(size=16),
            legend.title = element_text(size=18))
  }
  
  return(scatter)
}

# set up marginal histograms
draw.histogram <- function(x_or_y_var, data_var, aes_x_var, aes_fill_var, fill_value_var, m_rate) {
  if (m_rate == 0 | m_rate == 100) {
    b <- seq(0, 100, by=5)
  } else {
    b <- seq(0, 100, by=10)
  }
  
  if (fill_value_var == "grey") {
    b <- seq(0, 100, by=10)
  }
  
  histogram <- ggplot(data_var, 
                      aes(x = aes_x_var, 
                          fill = aes_fill_var)) +
    geom_histogram(breaks = b,
                   closed = "left",
                   color = "black",
                   alpha = 1.0,   # no alpha (transparency) since it is bad for b/w-print
                   position = "dodge") + # do not overlap, but show bars next to each other for "Yes/No"
    scale_y_continuous(breaks = c(0,500,1000), limits = c(0,1000)) +  # 1000 organisms/population
    scale_x_continuous(limits = c(0,100)) +
    scale_fill_manual(values = fill_value_var) +
    guides(fill = FALSE) +
    theme_light() +
    theme(axis.text = element_text(size = 16))
  
  if (x_or_y_var == "x") {  # histogram on top
    histogram <- histogram +
      theme(plot.margin = margin(),
            axis.text.x = element_blank(),
            axis.title = element_blank(),
            axis.ticks.x = element_blank(),
            panel.grid.minor = element_blank(),
            panel.grid.major.y = element_blank(),
            panel.grid.major.x = element_line(colour = "grey",size=0.2))
  } else if(x_or_y_var == "y") {  # histogram on the right
    histogram <- histogram +
      theme(plot.margin = margin(),
            axis.text.x = element_text(angle = 270, hjust = 1),
            axis.text.y = element_blank(),
            axis.title = element_blank(),
            axis.ticks.y = element_blank(),
            panel.grid.minor = element_blank(),
            panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(colour = "grey",size=0.2)) +
        coord_flip()
  } else {
    print("Error in function draw.histogram!")
  }
  
  return(histogram)
}

# generation plot
draw.gen <- function(m_rate, cur_gen, cur_rep) {
  mr_data = filter(snapshot_data, migration_rate==m_rate, update==cur_gen, replicate==cur_rep) 
  
  title <- ggdraw() +
    draw_label("  ")
  ##########################################################################################################
  migrated_scatter <- draw.scatter(mr_data, mr_data$scoreA, mr_data$scoreB, mr_data$migrated, "m", cur_gen)
  migrated_x_hist <- draw.histogram("x", mr_data, mr_data$scoreA, mr_data$migrated, colors, m_rate)
  migrated_y_hist <- draw.histogram("y", mr_data, mr_data$scoreB, mr_data$migrated, colors, m_rate)
  migrated_scat_hist <- ggarrange(migrated_x_hist, p_empty, migrated_scatter, migrated_y_hist, ncol=2, nrow=2, widths=c(4, 1), heights=c(1, 4))
  
  migrated_plot <- plot_grid(title, migrated_scat_hist, ncol=1, rel_heights=c(0.15, 1))
  ##########################################################################################################
  score_scatter <- draw.scatter(mr_data, mr_data$scoreA, mr_data$scoreB, mr_data$score, "s", cur_gen)
  score_x_hist <- draw.histogram("x", mr_data, mr_data$scoreA, mr_data$score, "grey", m_rate)
  score_y_hist <- draw.histogram("y", mr_data, mr_data$scoreB, mr_data$score, "grey", m_rate)
  score_scat_hist <- ggarrange(score_x_hist, p_empty, score_scatter, score_y_hist, ncol=2, nrow=2, widths=c(4, 1), heights=c(1, 4))
  
  score_plot <- plot_grid(title, score_scat_hist, ncol=1, rel_heights=c(0.15, 1))
  ##########################################################################################################
  combined_plot <- grid.arrange(migrated_plot, p_stripline_v, score_plot, ncol=3, widths = c(6,1,6))
  
  return(combined_plot)
}

##############################################################################################################################
######################################## GENERAL SETTINGS & GLOBAL VARIABLES #################################################
##############################################################################################################################

theme_set(theme_bw())

data_path <- "../2_FromHPCC/b_Migration/migration_scat_hist_snapshots.csv"

mr <- 0 # migration rate
cur_update <- 0
generations <- c(10,2500,5000)
colors <- c("#B8E186", "#C51B7D")
names(colors) <- c("Yes", "No")   # name colors to assure that green is always used for Yes and pink always for No

p_empty <- ggplot() + theme_void()
p_stripline_v <- ggplot() + geom_vline(xintercept = 50, size=2, color="grey85") + theme_void()
p_stripline_h <- ggplot() + geom_hline(yintercept = 50, size=2, color="grey85") + 
  geom_vline(xintercept = 50, size=2, color="grey85") + theme_void()

##############################################################################################################################
############################################## READ DATA & SET FACTORS #######################################################
##############################################################################################################################

snapshot_data <- read.csv(data_path, na.strings="NONE")

snapshot_data$migration_rate <- factor(snapshot_data$migration_rate,
                                       levels=c(0,10,20,30,40,50,60,70,80,90,100))
snapshot_data$migrated <- factor(snapshot_data$migrated, 
                                 levels=c("Yes", "No"))

##############################################################################################################################
##################################################### MAIN CODE ##############################################################
##############################################################################################################################

# 20 replicates per migration rate --> 20*11=220 replicates in total
for (i in 1:220) {
  rep <- 40000+i # get current random seed
  cur_update <- cur_update+1
  
  print(paste("replicate: ", rep))
  print(paste("cur_update: ", cur_update))
  print(paste("mr: ", mr))

  gen_10_plot <- draw.gen(mr, 10, rep)
  gen_2500_plot <- draw.gen(mr, 2500, rep)
  gen_5000_plot <- draw.gen(mr, 5000, rep)
  
  # combine and annotate plots with generation number
  combined <- cowplot::plot_grid(gen_10_plot, p_stripline_h, gen_2500_plot, p_stripline_h, gen_5000_plot,
                        labels = c("Generation 10", "", "Generation 2500", "", "Generation 5000"),
                        label_size = 20,
                        ncol = 1,
                        nrow = 5,
                        rel_heights = c(6.5,1,6.5,1,7.5))
  
  # add title
  plot_complete <- grid.arrange(combined,
                                top=textGrob(paste("Migration Rate: ", mr, "%, Replicate:", rep, "\n", sep = ""), gp=gpar(fontsize=22, font=2)))
   
  ggsave(paste("./b_scatterplots/scatterplot_mr_", mr, "_rep_", rep, ".png", sep = ""), plot_complete, width = 11, height = 20)
  
  if (cur_update == 20) {  # 20 replicates per migration rate
    cur_update <- 0
    mr <- mr + 10
  }
}