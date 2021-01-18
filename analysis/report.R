################################################################################
# Description: Short data report on carehome resident definitions
#
# Author: Emily S Nightingale
# Date: 15/01/2021
#
################################################################################

################################################################################

sink("./report_output.txt", type = "output")

library(tidyverse)
library(data.table)
library(knitr)

# library(here)
# setwd(here::here())

args <- c("output/input.csv", "output/cqc_by_msoa.csv")
# args = commandArgs(trailingOnly=TRUE)

options(datatable.old.fread.datetime.character=TRUE)

input <- fread(args[1], data.table = FALSE, na.strings = "") %>%
  # Filter just to records from England
  filter(grepl("E",msoa)) %>%
  mutate(nhse_care_home_des = replace_na(nhse_care_home_des,0),
         tpp_care_home_ind = as.numeric(tpp_care_home_type %in% c("PC","PN","PS")),
         across(c("ethnicity","ethnicity_16"), as.factor),
         across(where(is.character), as.factor))

table(input$tpp_care_home_type, input$nhse_care_home_des) %>% kable()
table(input$tpp_care_home_ind, input$nhse_care_home_des) %>% kable()


input %>%
  filter(tpp_care_home_ind | nhse_care_home_des) %>%
  mutate(source = as.factor(case_when((tpp_care_home_ind & 
                               nhse_care_home_des) ~ "Both",
                            (tpp_care_home_ind & 
                               !nhse_care_home_des) ~ "TPP only",
                            (!tpp_care_home_ind & 
                               nhse_care_home_des) ~ "NHSE only"))) -> ch_res

summary(ch_res$source)

ch_res %>%
  group_by(source) %>%
  summarise(age_minmax = paste(min(age, na.rm = T), max(age, na.rm = T),sep = "-"),
            age_quants = paste(quantile(age,na.rm = T, 0.25),
                              median(age, na.rm = T),
                              quantile(age,na.rm = T, 0.75),
                              sep = ","),
            age_meansd = paste0(round(mean(age, na.rm = T),0),
                                "(",
                               round(sd(age,na.rm = T),2),
                               ")"),
            p_female = mean(sex == "F"),
            p_vacc = mean(!is.na(covid_vacc)),
            med_IMD = median(index_of_multiple_deprivation))

ch_res %>%
  group_by(source) %>%
  group_split() -> by_source

lapply(by_source, summary)

## Compare MSOA totals with CQC beds

ch_res %>% 
  group_by(msoa) %>% 
  summarise(n.tpp = sum(tpp_care_home_ind == 1),
            n.nhse = sum(nhse_care_home_des == 1)) -> ch_res_by_msoa

cqc_msoa <- fread(args[2], data.table = FALSE, na.strings = "") %>%
  full_join(ch_res_by_msoa, by = c("msoa11cd" = "msoa")) %>%
  mutate(tpp_perc_cqc_beds = n.tpp*100/n.beds,
         nhse_perc_cqc_beds = n.nhse*100/n.beds)

summary(cqc_msoa)

sink()
