rm(list = ls())

library(tidyverse)
library(lubridate)
library(ggplot2)
library(rnoaa)

isd_data_dir <- "./"

# look into a folder with attr(extract_isd_data, "source")
# e.g. isd_path <- "/Users/ekaterina/Library/Caches/R/noaa_isd"
# isd_path <- attr(extract_isd_data, "source")
# e.g. isd_file <- "407540-99999-2013"
cache_path <- "~/Library/Caches/R/noaa_isd"

year_value <- 2013

# pick a point of interest -----------------------------------------------------

# look for observations which are closer to a given node than radius
# and extract data for the given year value from the fullest observalions set
# interactive map for a convenient stations selection
# https://www.ncei.noaa.gov/maps/hourly/

country_of_interest <- "CI"
radius_km <- 150
node_lat <- -33
node_lon <- -70

# find stations ----------------------------------------------------------------
isd_block_tbl <- isd_stations_search(
    lat = node_lat,
    lon = node_lon,
    radius = radius_km,
    bbox = NULL)

 # example of output
 #   usaf   wban  station_name         ctry  state icao     lat   lon elev_m    begin      end distance
 #   <chr>  <chr> <chr>                <chr> <chr> <chr>  <dbl> <dbl>  <dbl>    <dbl>    <dbl>    <dbl>
 # 1 400070 99999 ALEPPO INTL          SY    ""    "OSAP"  36.2  37.2  389.  19370105 20230414     28.5
 # 2 400170 99999 EDLEB                SY    ""    ""      35.9  36.6  451   19920615 19971214     35.3

# find the station with best data availability
isd_of_interest <- isd_block_tbl %>%
    dplyr::filter(
        ctry == country_of_interest,
        year(ymd(end)) >= 2022
        # # AF
        # year(ymd(end)) >= 2018
    ) %>%
    arrange(
        desc(ymd(begin))
    )

# select station in the region with the earlies begin of observations
isd_meta_selected_st <- isd_of_interest[nrow(isd_of_interest),]

# read main meta data directly from the observations set
usaf_value <- isd_meta_selected_st$usaf
wban_value <- isd_meta_selected_st$wban
country <- unique(isd_meta_selected_st$ctry)[1]

# load data --------------------------------------------------------------------
isd_file <- paste(usaf_value, wban_value, year_value, sep = "-")

if ( file.exists(file.path(cache_path, isd_file)) ){
    res_isd <- isd_parse(file.path(isd_path, isd_file))
} else {
    extract_isd_data <- isd(usaf = usaf_value, 
        wban = wban_value, year = year_value)
    res_isd <- extract_isd_data
}

# work with data ---------------------------------------------------------------
tas_df <- res_isd[, c("date", "time", "temperature", "temperature_quality")] %>%
    mutate(
        tas = ifelse(
            as.numeric(temperature)/10 > 900,
            NA,
            as.numeric(temperature)/10),
        date_time = ymd_hms(paste0(date, time, "00"))
    )

write.csv(
    tas_df,
    file.path(
        isd_data_dir,
        paste(country, 
              usaf_value,
              wban_value,
              "year", year_value,
              "tas.csv", 
              sep = "_")
    ),
    row.names = FALSE
)

pl <- tas_df %>%
    ggplot(aes(x = date_time, y = tas)) +
    geom_line(color = "forestgreen")
ggsave(
    file.path(
        isd_data_dir,
        paste(country,
              usaf_value,
              wban_value,
              "year", year_value, 
              "tas_ts.pdf", 
              sep = "_")
    ),
    pl,
    device = "pdf"
)

# collect meta -----------------------------------------------------------------

# quick quality check
isd_meta_selected_st$n_na_tas <- sum(is.na(tas_df$tas))
isd_meta_selected_st$n_non_credible_tas <- sum(tas_df$temperature_quality != 1)

write.csv(
    isd_meta_selected_st,
    file.path(
        isd_data_dir,
        paste(country,
              usaf_value,
              wban_value,
              "year", year_value,
              "tas_meta.csv",
              sep = "_")
    ),
    row.names = FALSE
)





