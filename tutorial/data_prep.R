#======================================================================
# Goal: Prepare data for tutorial
# Author: Hesu Yoon
# Updated: Sep 20 2024
# Data needed:
# 1) nh boundary data (polygon) -> no need to prep
# 2) nh-level demographics -> need to prep, cont vars, use to create gentcat
# 3) airbnb listings (lat and lon) -> geom point
# 4) biz (address) -> practice for geocoding
#=======================================================================

# set up
library(dplyr)
library(tidyverse)
library(sf)

########################
# clean nh-level demo
########################

# import data
sfdem <- read.csv("unclean data/nh_gent.csv")

# check column names
names(sfdem)

# select vars of interest
sfdem_filter <- sfdem %>%
  select("nhood", "tpop", "pyoung",
         "pcol", "minc", "mhval", "mrent", 
         "pwhite", "pblack", "pasian","phisp",
         "tpop17", "pyoung17", 
         "pcol17",  "minc17", "mhval17", "mrent17",
         "gentcat",
         "pwhite17", "pblack17", "pasian17", "phisp17")

write.csv(sfdem_filter, "sfdem.csv", row.names = FALSE)

####################  
# listings data
####################

sfbnb <- read.csv("unclean data/sf_analytic_sample_analysis.csv") %>%
  select("id", "trt10", "analysis")

sfbnb_geom <- read.csv("unclean data/sf_unique_listings_2019.csv") %>%
  select("id", "latitude", "longitude", 
         "property_type", "review_scores_rating", "review_scores_location", "number_of_reviews")

sfbnb_merge <- left_join(sfbnb, sfbnb_geom, by = 'id')

write.csv(sfbnb_merge, "sfbnb.csv", row.names = FALSE)

#################### 
# biz data
#################### 

sfbiz <- read.csv("unclean data/sf_merged_retail.csv") %>% 
  filter (archive_version_year == 2019 
          & restaurant == 1) %>%
  select("company", "address_line_1", "city", "zipcode",
         "naics8_descriptions", "employee_size_location", "sales_volume_location")  %>%
  mutate(state = "CA")

write.csv(sfbiz, "sfbiz.csv", row.names = FALSE)

#################### 
# boundary data
#################### 

# read in
sftrt <- st_read("data/sfnh_trt.geojson")

# check
head(sftrt, 3)

# find places outside nh analysis
unique(sftrt$neighborhoods_analysis_boundaries)

# filter islands
sftrt_clean <- sftrt %>%
  filter(neighborhoods_analysis_boundaries != "The Farallones")

# export
st_write(sftrt_clean, "sftrt_clean.geojson", driver = "GeoJSON")

