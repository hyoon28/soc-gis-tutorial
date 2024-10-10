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

# import data - nh analysis level
sfdem <- read.csv("sample data/nh_gent.csv")

# check column names
names(sfdem)

# select vars of interest
sfdem_filter <- sfdem %>%
  select("nhood","pwhite17", "pblack17", "pasian17", "phisp17")

write.csv(sfdem_filter, "sfnh_dem.csv", row.names = FALSE)

# import data - census tract level
trtdem <- read.csv("sample data/gentmeasure0017.csv")

# checkc columns
names(trtdem)

# select vars of interest
trtdem_filter <- trtdem %>%
  select("trt10", "tpop", "pyoung",
         "pcol", "minc", "mhval", "mrent", 
         "pwht", "pblk", "pasian","phisp",
         "tpop17", "pyoung17", 
         "pcol17",  "minc17", "mhval17", "mrent17",
         "pwht17", "pblk17", "pasian17", "phisp17",
         "gent2")

trtdem_filter <- trtdem_filter %>%
  rename(gentcat = gent2) %>%
  filter(tpop17 != 0)

write.csv(trtdem_filter, "sftrt_dem.csv", row.names = FALSE)


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

sfbiz <- read.csv("sample data/sf_merged_retail.csv") %>% 
  filter (archive_version_year == 2019 
          & restaurant == 1) %>%
  select("company", "address_line_1", "city", "zipcode",
         "naics8_descriptions")  %>%
  mutate(state = "CA") %>%
  mutate(full_add = paste(address_line_1, city, state, zipcode, sep = ", "))

library(tidygeocoder)

# geocode the full address
geocoded_sfbiz <- sfbiz %>%
  geocode(address = full_add, method = 'osm')

# omit rows where lat or long is missing (NA)
geocoded_sfbiz_clean <- geocoded_sfbiz %>%
  filter(!is.na(lat) & !is.na(long))

sfbiz_clean <- geocoded_sfbiz_clean %>%
  select(!c(lat, long, full_add))

# export the clean file
write.csv(geocoded_sfbiz_clean, "geocoded_sfbiz_clean.csv", row.names = FALSE)
write.csv(sfbiz_clean, "sfbiz_clean.csv", row.names = FALSE)


#################### 
# boundary data
#################### 

# read in
sftrt <- st_read("data/sfnh_trt.geojson")

# check
head(sftrt, 3)

# find places outside nh analysis
unique(sftrt$nhood)

# columns check
names(sftrt)

# select variables of interest
sftrt_clean <- sftrt %>%
  select("nhood",
         "tractce10",
         "geometry")

# export
st_write(sftrt_clean, "sftrt_clean.geojson", driver = "GeoJSON")

## for 2020 census tract geo

# filter islands
sftrt_clean <- sftrt %>%
  filter(neighborhoods_analysis_boundaries != "The Farallones")

# rename
sftrt_clean <- sftrt_clean %>%
  rename("nhood" = "neighborhoods_analysis_boundaries")
