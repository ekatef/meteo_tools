# read and explore GRDC data on runoff

rm(list = ls())

library(lubridate)
library(ncdf4)
library(raster)
library(terra)
library(tidyverse)

data_dir <- "./"
data_fl <- "GRDC_Daily.nc"
fl <- file.path(data_dir, "GRDC_Daily.nc")

# read nc content --------------------------------------------------------------
nc_data <- nc_open(fl)
print(nc_data)
runoff_nc <- ncvar_get(nc_data, varid="runoff_mean")
st_id_nc <- ncvar_get(nc_data, varid="station_name")
time_nc <- ncvar_get(nc_data, varid="time")
attrs_nc <- ncatt_get(nc_data, varid = 0)
nc_close(nc_data)

# time is measures in seconds since 1700
t_test <- as.POSIXct(time_nc*24*60*60, origin = "1700-01-01", tz="UTC")
print(head(t_test))
print(tail(t_test))

# show timeseries plot ---------------------------------------------------------
year_to_zoom <- 1975
i_start <- min(which(year(as.Date(t_test)) > year_to_zoom))

pdf("test_nz.pdf")
plot(
    x = t_test[i_start:length(t_test)],
    y = runoff_nc[1, i_start:length(t_test)],
    col = "cornflowerblue",
    type = "l",
    xlab = "datetime",
    ylab = "daily discharge [m^3/s]"
)
dev.off()


