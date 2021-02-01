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

# Send output to an output text file 
logfile <- file("./analysis/01_cross_tabulations.txt")
sink(logfile, append=TRUE)
sink(logfile, append=TRUE, type="message")

args = commandArgs(trailingOnly=TRUE)

print("These are my input arguments")
print(args[1])

print("This is my workspace")
getwd() 

inputdata <- toString(args[1]) 

# Read in Data -----------------------------------------------------------
study_population <- fread(inputdata, data.table = FALSE, na.strings = "")

# Define care home variables  ---------------------------------------------

# Diagnostic codes 
study_population <- study_population %>% 
  ## replace missing entries codes with zero
  mutate(snomed_carehome_ever = replace_na(snomed_carehome_ever, 0), 
         snomed_carehome_pastyear = replace_na(snomed_carehome_pastyear, 0)) 

# Address Linkage 
study_population <- study_population %>% 
  ## replace abbreviations with meaningful terms (expecting NAs to be retained as NAs)
  mutate(tpp_care_home_cat = case_when(
    tpp_care_home_type == "PC" ~ "Care Home", 
    tpp_care_home_type == "PN" ~ "Nursing Home", 
    tpp_care_home_type == "PS" ~ "Care or Nursing Home", 
    tpp_care_home_type == "U" ~ "Private Home")) %>% 
  ## create binary indicator for in any care home type by address linkage (expecting NAs to be retained as NAs)
  mutate(tpp_care_home = ifelse(str_detect(tpp_care_home_type,'PC|PN|PS'),1,0)) 

# Household ages and size  
study_population <- study_population %>% 
  # if more than 4 people in household >= 65, class everyone in the household as being in a care home
  # first make indicator for people >= 65 
  mutate(old = ifelse(age >= 65, 1, 0)) %>% 
  # count old by household 
  group_by(household_id) %>% 
  mutate(old_count = sum(old)) %>%
  ungroup() %>% 
  # if old_count is >= 4, assign as in a care home 
  mutate(household_care_home = ifelse(old_count >= 4, 1, 0)) %>% 
  # there are invalid household IDs. In a slightly hacky getaround put those with invalid hosuehold IDs to NA. 
  mutate(household_care_home = replace(household_care_home, household_id <= 0, NA))

summary(study_population$household_id)

# Tabulations  ------------------------------------------------------------

print("SNOMED code prevalence, ever")

diagnostic_codes <- study_population %>% 
  tabyl(snomed_carehome_ever) %>% 
  adorn_totals() %>% 
  adorn_pct_formatting(digits = 2)

diagnostic_codes 

print("SNOMED code prevalence, past year")

diagnostic_codes_recent <- study_population %>% 
  tabyl(snomed_carehome_pastyear) %>% 
  adorn_totals() %>% 
  adorn_pct_formatting(digits = 2)

diagnostic_codes_recent 

print("Address linkage prevalence")

address_linkage <- study_population %>% 
  tabyl(tpp_care_home) %>% 
  adorn_totals() %>% 
  adorn_pct_formatting(digits = 2)

address_linkage 

print("Household size and age prevalence")

hh_size_age <- study_population %>% 
  tabyl(household_care_home) %>% 
  adorn_totals() %>% 
  adorn_pct_formatting(digits = 2)

hh_size_age 

# Cross Tabulations (2 x 2)  ----------------------------------------------
## only considering care home codes ever in the first round of this apart from internal check
## have not added percentages as there is no gold standard, so row vs column both seemed hard to interpret

print("Recent vs Past")

diagnostics <- study_population %>% 
  tabyl(snomed_carehome_ever, snomed_carehome_pastyear) %>% 
  adorn_totals() 

diagnostics 

print("Diagnostic vs address")

diagnostic_address <- study_population %>% 
  tabyl(snomed_carehome_ever, tpp_care_home) %>% 
  adorn_totals() 

diagnostic_address 

print("Household vs address")

household_address <- study_population %>% 
  tabyl(household_care_home, tpp_care_home) %>% 
  adorn_totals() 

household_address 

print("Household vs Diagnostic")

household_snomed <- study_population %>% 
  tabyl(household_care_home, snomed_carehome_ever) %>% 
  adorn_totals() 

household_snomed 

# Summary of Identification Methods  --------------------------------------
## add percentage and counts of people identified using each combination of method 

carehome_methods <- c("snomed_carehome_ever", "tpp_care_home", "household_care_home")

ch_methods_summary <- study_population %>% 
  count(across(all_of(carehome_methods))) 

print("OVerlap across identification methods") 
ch_methods_summary 

# send output back to screen
sink() 
sink(type="message")



