# Program Information  ----------------------------------------------------

# Program:     02_characteristics.R
# Author:      Anna Schultze
# Description: Brief characteristics of care home residents identified using different methods
# Input:       input.csv
# Output:      Text files into output 
# Edits:

# Housekeeping  -----------------------------------------------------------

# load packages
library(data.table)
library(tidyverse)
library(janitor)

# Create a subdirectory to save outputs in 
mainDir <- getwd() 
subDir <- "./analysis/outfiles"

if (file.exists(subDir)){
  print("Out directory exists")
} else {
  dir.create(file.path(mainDir, subDir))
  print("Out directory didn't exist, but I created it")
}

# Send output to an output text file in the output directory 
logfile <- file("./analysis/outfiles/02_characteristics.txt")
sink(logfile, append=TRUE)
sink(logfile, append=TRUE, type="message")

# Functions ---------------------------------------------------------------

# 1. tabulate 
# tabulate a single variable but add and format percentages  
tabulate <- function(data,varname) { 
  
  {{data}} %>% 
    tabyl({{varname}}) %>%
    adorn_totals() %>%
    adorn_pct_formatting(digits = 2)
  
}

# 2. tabulate_many 
#    function to tabulate multiple binary variables into a small and basic table 
#    input values is the dataset, a filtervar, and all variables (quoted) you want to describe. 
#    create a total var to get around the filtering function 

tabulate_many <- function(data, filtervar, ...) {
  
    {{data}} %>% 
    filter({{filtervar}} == 1) %>% 
    select(...) %>% 
    summarise(
    across(
      .cols  = everything(),
      list(count = sum, percent = mean), 
      na.rm = TRUE, 
      .names = "{.fn}-{.col}")) %>% 
    pivot_longer(everything(), 
                 names_to = c(".value", "variable"), 
                 names_sep = "-") %>% 
    mutate(percent = round(percent*100, 2))
  
}

# Read in Data ------------------------------------------------------------
study_population <- fread("./output/study_population.csv", data.table = FALSE, na.strings = "")

# TPP coverage ------------------------------------------------------------

# check coverage for missingness and values
summary(study_population$tpp_coverage) 

# create variables to summarise coverage at different levels 
care_home_coverage <- study_population %>% 
  # restrict to existing household IDs and calculate coverage by household
  filter(!is.na(household_id)) %>% 
  group_by(household_id) %>% 
  # create a series of cutoffs to estimate % of care homes with different coverage (expecting NAs to be retained)
  mutate(tpp_coverage_75 = if_else(tpp_coverage >=75, 1, 0), 
         tpp_coverage_80 = if_else(tpp_coverage >=80, 1, 0), 
         tpp_coverage_85 = if_else(tpp_coverage >=85, 1, 0), 
         tpp_coverage_90 = if_else(tpp_coverage >=90, 1, 0), 
         tpp_coverage_95 = if_else(tpp_coverage >=95, 1, 0)) %>% 
  ungroup() %>% 
  distinct(household_id, .keep_all = TRUE)

# tabulate (old way as I want to check the NAs)
tabulate(care_home_coverage, tpp_coverage_75)
tabulate(care_home_coverage, tpp_coverage_80)
tabulate(care_home_coverage, tpp_coverage_85)
tabulate(care_home_coverage, tpp_coverage_90)
tabulate(care_home_coverage, tpp_coverage_95)

# Data Management  --------------------------------------------------------
# need to create indicator variables to tabulate characteristics 
# consciously using base ifelse here as type differences for many vars that are not actually important 

vars = c("cancer", "diabetes", "chronic_cardiac_disease", "chronic_respiratory_disease", "stroke", "dementia")

study_population <- study_population %>% 
  mutate_at((c(vars)), ~ifelse(is.na(.), 0, .)) %>% 
  mutate(white = ifelse(ethnicity == 1, 1, 0),
        male = ifelse(sex == "M", 1, 0), 
        over80 = ifelse(age >= 80, 1, 0), 
        total = 1) 

# Characteristics by care home variable  ----------------------------------

tabvars <- c("male", "over80", "white", "dementia", "stroke", "cancer", "diabetes", "chronic_cardiac_disease", "chronic_respiratory_disease")

print("Total characteristics")
tabulate_many(study_population, total, tabvars)

print("TPP care home characteristics")
tabulate_many(study_population, tpp_care_home, tabvars)

print("Household care home characteristics")
tabulate_many(study_population, household_care_home, tabvars)

print("Coded events care home characteristics")
tabulate_many(study_population, total, tabvars)

# send output back to screen
sink()
sink(type="message")

