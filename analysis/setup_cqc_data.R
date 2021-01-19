################################################################################
# Description: Short data report on carehome resident definitions
#
# Author: Emily S Nightingale
# Date: 18/01/2021
#
################################################################################

################################################################################

sink("./cqc_setup_log.txt", type = "output")

library(tidyverse)
library(data.table)
library(knitr)

# library(here)
# setwd(here::here())

# args <- c("data/pc_to_msoa.csv","data/4_January_2021_HSCA_Active_Locations.csv")
args <- c("data/pc_to_msoa.csv","data/carehomes_cqc.csv")

# args = commandArgs(trailingOnly=TRUE)

options(datatable.old.fread.datetime.character=TRUE)

rename_col <- function(name){
  name <- trimws(
    tolower(
    gsub(" ",".",
         gsub("[[:punct:]]","",name))))
}

pc_to_msoa <- fread(args[1], data.table = FALSE)

cqc <- fread(args[2], data.table = FALSE) %>%
  # Filter just to care homes
  filter(`Care home?` == "Y") %>%
  mutate(across(where(is.character), as.factor)) %>%
  rename_with(rename_col, everything())

print(paste("Total with `care home = Y`: ", nrow(cqc)))

print(paste("Total care home beds: ", sum(cqc$care.homes.beds, na.rm = TRUE)))

names(cqc) <- str_replace(names(cqc),"regulated.activity..","")
names(cqc) <- str_replace(names(cqc),"service.type..","")
names(cqc) <- str_replace(names(cqc),"service.user.band..","")
names(cqc) <- str_replace(names(cqc),"accommodation.for.persons.who.require.","")

cqc_select <- cqc %>%
  filter(older.people == "Y") %>%
  dplyr::select(care.homes.beds,location.typesector, location.latest.overall.rating,
                location.region, location.local.authority, location.onspd.ccg.code,
                location.onspd.ccg, location.postal.code, brand.id, brand.name,
                nursing.or.personal.care, nursing.care, personal.care,
                care.home.service.with.nursing, care.home.service.without.nursing,
                dementia) %>%
  left_join(pc_to_msoa, by = c("location.postal.code" = "pcds")) %>%
  mutate(across(is.character, as.factor)) 

print(paste("With `service user band - older.people`: ", nrow(cqc_select)))
print(paste("Total beds, with `service user band - older.people`: ", sum(cqc_select$care.homes.beds, na.rm = TRUE)))

print(paste("Matched with MSOA: ", nrow(filter(cqc_select, !is.na(msoa11cd)))))

summary(cqc_select)

table(cqc_select$nursing.or.personal.care, cqc_select$care.home.service.with.nursing)
table(cqc_select$nursing.or.personal.care, cqc_select$care.home.service.without.nursing)

table(cqc_select$nursing.care, cqc_select$care.home.service.with.nursing)
table(cqc_select$personal.care, cqc_select$care.home.service.without.nursing)

cqc_select %>%
  group_by(care.home.service.with.nursing) %>%
  summarise(beds = sum(care.homes.beds))

cqc_msoa <- cqc_select %>%
  group_by(location.region, msoa11cd, msoa11nm) %>%
  summarise(n = n(), 
            n.beds = sum(care.homes.beds, na.rm = T))

write.csv(cqc_select, "./output/cqc_all.csv", row.names = F)
write.csv(cqc_msoa, "./output/cqc_by_msoa.csv", row.names = F)

sink()
