# Program Information  ----------------------------------------------------

# Program:     01_cross_tabulations.R
# Author:      Anna Schultze
# Description: Brief tabulations and cross tabulations of care home identifiers
# Input:       input.csv
# Output:      table1_[year].txt
# Edits:

# Housekeeping  -----------------------------------------------------------

# load packages
library(data.table)
library(tidyverse)
library(janitor)

# Create a subdirectory to save outputs in 
mainDir <- getwd() 
subDir <- "./analysis/outfiles"

dir.create(file.path(mainDir, subDir))

# Send output to an output text file
logfile <- file("./analysis/outfiles/01_cross_tabulations.txt")
sink(logfile, append=TRUE)
sink(logfile, append=TRUE, type="message")

# Functions --------------------------------------------------------------
# custom tabyls to reduce some typing for tabs and crosstabs 

# 1. tabulate 
# tabulate a single variable but add and format percentages  
tabulate <- function(data,varname) { 
  
  {{data}} %>% 
    tabyl({{varname}}) %>%
    adorn_totals() %>%
    adorn_pct_formatting(digits = 2)
  
}

# 2. crosstabulate
# tabulate two variables but add totals 
crosstabulate <- function(data, varname1, varname2) { 
  
 {{data}} %>% 
    tabyl({{varname1}}, {{varname2}}) %>%
    adorn_totals()
  
} 

# Read in Data -----------------------------------------------------------
study_population <- fread("./output/input.csv", data.table = FALSE, na.strings = "")

# Define care home variables  ---------------------------------------------

# Diagnostic codes
study_population <- study_population %>%
  ## replace missing entries codes with zero
  mutate(snomed_carehome_ever = replace_na(snomed_carehome_ever, 0),
         snomed_carehome_pastyear = replace_na(snomed_carehome_pastyear, 0))

# Address Linkage
study_population <- study_population %>%
  mutate(
    ## replace abbreviations with meaningful terms (expecting NAs to be retained as NAs)
    tpp_care_home_cat = case_when(
      tpp_care_home_type == "PC" ~ "Care Home",
      tpp_care_home_type == "PN" ~ "Nursing Home",
      tpp_care_home_type == "PS" ~ "Care or Nursing Home",
      tpp_care_home_type == "U" ~ "Private Home"
    ),
    ## create binary indicator for in any care home type by address linkage (expecting NAs to be retained as NAs)
    tpp_care_home = ifelse(str_detect(tpp_care_home_type,'PC|PN|PS'),1,0)
  )

# Household ages and size
study_population <- study_population %>%
  # if more than 4 people in household >= 65, class everyone in the household as being in a care home
  # first make indicator for people >= 65
  mutate(old = ifelse(age >= 65, 1, 0)) %>%
  # count old by household
  group_by(household_id) %>%
  mutate(old_count = sum(old)) %>%
  ungroup() %>%
  mutate(
    # if old_count is >= 3, assign as in a care home
    household_care_home = ifelse(old_count >= 3, 1, 0),
    # there are invalid household IDs. In a slightly hacky getaround put those with invalid hosuehold IDs to NA.
    household_care_home = ifelse(household_id<=0, NA, household_care_home)
  )

# save this dataset so it can be used in other actions 
fwrite(study_population, "./output/study_population.csv")

# Tabulations  ------------------------------------------------------------

tabulate(study_population, snomed_carehome_ever)
tabulate(study_population, snomed_carehome_pastyear)
tabulate(study_population, household_care_home)
tabulate(study_population, tpp_care_home)

# Cross Tabulations (2 x 2)  ----------------------------------------------
## have not added percentages as there is no gold standard, so row vs column both seemed hard to interpret

crosstabulate(study_population, snomed_carehome_ever, snomed_carehome_pastyear) 
crosstabulate(study_population, snomed_carehome_ever, tpp_care_home) 
crosstabulate(study_population, household_care_home, tpp_care_home) 
crosstabulate(study_population, household_care_home, snomed_carehome_ever) 

# Summary of Identification Methods  --------------------------------------

carehome_methods <- c("snomed_carehome_ever", "tpp_care_home", "household_care_home")

ch_methods_summary <- study_population %>%
  count(across(all_of(carehome_methods)))

print("OVerlap across identification methods")
ch_methods_summary

# send output back to screen
sink()
sink(type="message")


