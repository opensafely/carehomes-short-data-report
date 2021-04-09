# Program Information  ----------------------------------------------------

# Program:     03_figures.R
# Author:      Anna Schultze
# Description: Make a Venn and bar chart from the summary data 
# Input:       the input is hard coded because the required package is not available on the OS server as of yet
#              input is taken from the final output table of 01_cross_tabulations
#              longer term I will use that output and read it in for automation, but will require adding eulerr to docker image on OS server 
# Output:      figure in outfiles 
# Edits:

# Housekeeping  -----------------------------------------------------------

# load packages
library(data.table)
library(tidyverse)
library(janitor)
library(eulerr)
library(ggplot2)

# Euler Diagram  ----------------------------------------------------------

df1 <- euler(c("AddressLinkage" = 6804, "Household" = 37917, "CodedEvents" = 13382,
                "AddressLinkage&Household" = 34248, "AddressLinkage&CodedEvents" = 6677, "Household&CodedEvents" = 13607,
                "AddressLinkage&Household&CodedEvents" = 53210), shape = "ellipse")
plot(df1, quantities = TRUE)
error_plot(df1)

# Stacked Bar Charts ------------------------------------------------------

Baseline_Method  <- c(rep(c("Address Linkage", "Household", "Coded Event"), each = 4))
Overlap_Method  <- c(rep(c("Address Linkage", "Household", "Coded Event", "All Methods"), times = 3))
Frequency <- c(6.740704782, 33.92940291, 6.614886218, 52.71500609, 24.64203998, 27.28195018, 9.790476465, 38.28553338, 7.685666928, 15.66255352, 15.4035637, 61.24821585)

df2 <- data.frame(Baseline_Method, Overlap_Method, Frequency)

df2 <- df2 %>% 
  mutate(Frequency = round(Frequency,2)) 

ggplot(df2, aes(x = Baseline_Method, y = Frequency, fill = Overlap_Method, label = Frequency)) +
  geom_bar(stat = "identity") +
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(x = "Method for Identifying Potential Care Home Residents", 
     y = "Percentage", 
     fill = "Also identified with...") + 
  scale_fill_viridis_d() + 
  theme(axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0)), 
        axis.title.x = element_text(margin = margin(t = 20, r = 0, b = 0, l = 0)),
        plot.title = element_text(margin = margin(t = 0, r = 0, b = 20, l = 0)),
        panel.background = element_blank(), 
        axis.line = element_line(colour = "gray")) 



