import os

import atlite
import country_converter as coco
import geopandas as gpd
import numpy as np
import pandas as pd
import progressbar as pgb
import xarray as xr

import matplotlib.pyplot as plt

st_id = "BL_851960_99999"

fn_path = "./"

fn_meta_fl = st_id + "_year_2013_tas_meta.csv"
fn_data_fl = st_id + "_year_2013_tas.csv"

cutout_path = "./"
cutout_fl = "africa-2013-era5.nc"

meta_df = (
    pd.read_csv(
        os.path.join(fn_path, fn_meta_fl),
        comment="#",
        keep_default_na=False,
        na_values=["NA"],
        index_col=0,
    )
)

obs_df = (
    pd.read_csv(
        os.path.join(fn_path, fn_data_fl),
        comment="#",
        keep_default_na=False,
        na_values=["NA"],
        # index_col=0,
        index_col="date_time"
    )
    .drop(columns = ["time", "date"])
)
# TODO Should be fixed on the data extraction step
obs_df.drop(obs_df.loc[obs_df["temperature"]>900].index, inplace=True)
obs_df["temperature"] = (obs_df["temperature"]/10) + 273.15
obs_df.index.name = "time"

cutout_array = xr.open_dataset(os.path.join(cutout_path, cutout_fl))
temper_array = cutout_array["temperature"]
point_ts = temper_array.sel(y=meta_df.lat.values[0], x=meta_df.lon.values[0], method='nearest')

# quantify differences between the reanalysis and observations
print(point_ts.mean() - 273.15)
print(point_ts.max() - 273.15)
print(point_ts.min() - 273.15)
print(point_ts.std())

print(np.mean(obs_df.tas))
print(np.max(obs_df.tas))
print(np.min(obs_df.tas))
print(np.std(obs_df.tas))

era5_df = (
    point_ts.to_dataframe()
    .rename(columns={"temperature": "temperature_era5"})
    .drop(["x", "y", "lon", "lat"], axis=1)
)
era5_df.index = pd.to_datetime(era5_df.index, format="%Y-%m-%d %H:%M:%S")

plt.plot(obs_df["temperature"], color = "green", alpha = 0.5)
plt.savefig(os.path.join(fn_path, st_id + "_" + "ts_obs.pdf"))

fig, ax = plt.subplots()
ax.plot_date(pd.to_datetime(era5_df.index), era5_df["temperature_era5"], 
    linestyle="-", color="dodgerblue", marker="")
plt.savefig(os.path.join(fn_path, st_id + "_" + "ts_era5.pdf"))


fig, ax = plt.subplots()
ax.plot_date(pd.to_datetime(era5_df.index), era5_df["temperature_era5"] - 273.15, 
    linestyle="-", color="dodgerblue", marker="", alpha = 0.5, label="era5")
ax.plot_date(pd.to_datetime(obs_df.index), obs_df["temperature"] - 273.15, 
    linestyle="-", color="forestgreen", marker="", alpha = 0.5, label="obs")
# # works better for Southern Hemisphere
# plt.legend(loc="upper center")
plt.legend(loc="lower center")
plt.savefig(os.path.join(fn_path, st_id + "_" + "era5_vs_obs.pdf"))