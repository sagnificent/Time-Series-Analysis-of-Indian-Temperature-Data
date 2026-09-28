# Time Series Analysis of Indian Temperature Data

A SARIMA-based study of India's monthly average land temperature from **January 1880 to August 2013**, covering trend detection, seasonal differencing, model selection, and out-of-sample forecasting.

Course project for Statistical Methods 4.

## Data

`Datasets/GlobalLandTemperaturesByCountry.csv` — Berkeley Earth's *Global Land Temperatures by Country* series (distributed via the Kaggle "Climate Change: Earth Surface Temperature Data" set). Records are filtered to `Country == "India"` and truncated to the period beginning 1880, since earlier records carry substantially larger measurement uncertainty.

After dropping missing values this yields **1,604 monthly observations**, modelled as a time series of frequency 12 and split **80/20** into 1,283 training and 321 test points.

## Method

1. **Stationarity check** — KPSS test on the raw series indicates a non-stationary process.
2. **Trend detection** — a Seasonal Mann–Kendall test (`trend::smk.test`) confirms a significant trend in the seasonal data.
3. **Differencing** — a lag-1 difference removes the trend (re-confirmed by Mann–Kendall), then a lag-12 difference removes the seasonal component. KPSS and ADF tests both confirm the differenced series is stationary.
4. **Order identification** — ACF cuts off after lag 1–2 while PACF decays, pointing to a seasonal MA component. Two candidates are carried forward:
   - `SARIMA(0,1,1)(0,1,1)[12]`
   - `SARIMA(0,1,2)(0,1,1)[12]`
5. **Model selection** — Ljung–Box portmanteau tests at lag 12 and residual RMSE.
6. **Forecasting** — 321 months ahead with 95% confidence bands, compared against the held-out test set.

## Results

`SARIMA(0,1,2)(0,1,1)[12]` is the selected model. Its residuals pass the Ljung–Box test at lag 12 (consistent with i.i.d. errors), whereas the `(0,1,1)(0,1,1)[12]` residuals remain significantly autocorrelated. It also attains the lower residual RMSE, so both criteria agree.

Forecasts over the held-out period reproduce the seasonal cycle, with the observed series remaining inside the 95% confidence bands.

## Reproducing

Package versions are pinned with [renv](https://rstudio.github.io/renv/). Requires **R 4.6.1**.

```r
renv::restore()   # installs the exact package versions from renv.lock
```

Then run `India Temperature.R` from the project root — the dataset is read via a relative path, so the working directory must be the project directory (opening `SM 4 - Project.Rproj` handles this).

Key packages: `forecast`, `tseries`, `trend`, `Kendall`, `readr`.

> Install any further packages with `renv::install()` rather than `install.packages()`, so they land in the project library and stay recorded in the lockfile.

## Repository layout

| Path | Contents |
| --- | --- |
| `India Temperature.R` | Main analysis: tests, differencing, model fitting, forecast |
| `Datasets/` | Source temperature data (22 MB CSV) |
| `Plots/` | Generated figures |
| `Tangents/` | Exploratory side analyses, not part of the main result |
| `Stat_4_Project.pdf` | Written report |
| `Stat_4_presentation.pdf` | Presentation slides |
| `renv.lock` | Pinned package versions |
