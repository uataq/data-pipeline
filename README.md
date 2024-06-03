# Repository structure

The trace gas processing pipeline is structured as follows. This is executed on the smaug interactive node of the University of Utah's CHPC. The following paths are relative to the base path `/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline` -

1. `process_data.sh` is the shell scripting control layer called by cron that sets environment variables and executes necessary processing code.
1. `run/<stid>.r` called in parallel and executes site-specific processing code. By separating each site's initialization script, we can inject site specific processing code at strategic points in the data pipeline (e.g. after performing quality control but before calibrating measurements).
1. `src/` contains the bulk of processing source code as R functions.
1. `bad/` contains site/instrument specific bad data files for manual correction or removal of data. Changes are reflected at the QAQC and calibrated data levels.
1. `config/` contains JSON configurations for data structure and site metadata.
1. `.lock/` contains lock files in the form of `<stid>.lock` to indicate active site processing and prevent duplicate execution.

![](assets/workflow.png)

# Dataset details

## Site metadata

Site metadata can be found in [`config/site_config.csv`](config/site_config.csv) and at [air.utah.edu](http://air.utah.edu).

## Instruments

| Instrument              | Abbreviation   | Pollutants                     |
| ----------------------- | -------------- | ------------------------------ |
| 2B 205                  | 2b_205         | O<sub>3</sub>                  |
| GPS                     | gps            | &mdash;                        |
| Licor 6262 IRGA         | licor_6262     | CO<sub>2</sub>                 |
| Licor 7000 IRGA         | licor_7000     | CO<sub>2</sub>                 |
| Los Gatos Research NO2  | lgr_no2        | NO<sub>2</sub>                 |
| Los Gatos Research UGGA | lgr_ugga       | CH<sub>4</sub>, CO<sub>2</sub> |
| Magee AE33              | magee_ae33     | BC                             |
| MetOne ES642            | metone_es642   | PM<sub>2.5</sub>               |
| Teledyne T200           | teledyne_t200  | NO, NO<sub>2</sub>             |
| Teledyne T300           | teledyne_t300  | CO                             |
| Teledyne T400           | teledyne_t400  | O<sub>3</sub>                  |
| Teledyne T500u          | teledyne_t500u | NO<sub>2</sub>                 |
| TEOM 1400ab             | teom_1400ab    | PM<sub>2.5</sub>               |

## Processing Levels

Data is archived into different levels within each `measurements/data/<stid>/<instrument>` directory. Instrument column names and data types are defined for each processing level in [`config/data_config.json`](config/data_config.json).

### Raw

Data received from instruments are archived to the `raw` directory. The intention is that these files should never be touched.

> In extreme cases, this data has been altered such as when files were erroneously copied, to add missing column headers, and to split gps data by nmea sentence.

Raw files with a `dat` extension are recorded via a CR1000 datalogger, while raw files with a `csv` extension are recorded via a raspberry pi running [air-trend](https://github.com/jmineau/air-trend).

### QAQC

After archiving raw data, [QAQC flags](QAQC_Flags.md) are applied to each dataset and written to the `qaqc` archive.

To filter QAQC'd data, use `QAQC_Flag >= 0`

For instructions on how to manually flag data or remove automatic flags, see [Revising historic data](#revising-historic-data).

### Calibrated

This level exists only for instruments which receive calibration during post-processing. This would include the greenhouse gas instruments: `licor_6262`, `licor_7000`, and `lgr_ugga`. More information for this level is in [Calibration](Calibration.md).

Other instruments like the teledynes which receive manual, asynchronous calibrations do not have a `calibrated` level, as the raw data is already calibrated. Other instruments like the `gps` do not receive calibrations.

### Final

All instruments are finalized by removing rows with `QAQC_Flag < 0` and reducing to the essentials columns before writing to the `final` archive. Any reference gas measurement rows (`ID` >= 0) are also removed.

This level is intended to be the go-to level for most purposes, including sharing with third parties, with the exception of diagnostics.

# Workflows

## Declaring active instruments

A site's instrument ensemble can change over time. Active instruments are declared in the `instruments` column of [`config/site_config.csv`](config/site_config.csv). This column is a space-separated list of instrument abbreviations. Processing code for instruments not declared in this column will only be executed if [reprocessing is enabled](#reprocessing-raw-data).

## Revising historic data

Changes in the historic datasets can be made using the `bad/` data text files. When a new commit is made, the historic record for the given instrument is reprocessed on the next run (every 15 minutes).

- To pass data which has automatically been flagged, set `ID_new='ok'`. This will not replace the ID in the data.
- To remove data, set `ID_new=NA`.
- To update the known concentration of a measured tank, set the new concentration in `ID_new` and the old concentration in `ID_old`.
- To match a subset of the data, match the `ID_old` configuration with the valve identification stored in the datasets. For example, to remove a particular tank with a concentration of 499.89 ppm CO2 from the record, set `ID_old=499.89`.
- To match all of the data over a given time interval, set `ID_old=all`.

> ID is synonymous with the MIU description from the LGR's Multi Inlet Units, but encompasses all instruments.

## Reprocessing raw data

Ocassionally, raw data may need to be reprocessed (ex. applying new QAQC routine). Instrument data can be reprocessed via the `reprocess` column in [`config/site_config.csv`](config/site_config.csv).
- Reprocess all the instruments (active or not) at a site by setting `reprocess=TRUE`.
- Reprocess a specific instrument at a site by setting `reprocess=<instrument_abbreviation>`.
- Specify multiple instruments by seperating their abbreviation with a space.

## Site not updating

Sites on air.utah.edu can be offline for several reasons, including

1. Power at the site
1. Networking issues
1. CHPC pipeline locks

### Fixing CHPC pipeline locks

To prevent concurrency issues (e.g. two processes attempting to write to the same raw data file at the same time), we use lock files to signify when a site is currently being processed. These files are created at `.lock/<stid>.lock` when a site begins updating and are removed when the site update successfully completes.

However, many issues (some out of our control) can prevent site processing from completing successfully. A user on CHPC can consume all of the available memory on the same node, causing the operating system to kill running processes. Connection outages during transfers can cause timeouts.

There are many potential causes of these issues - fortunately, the fix is usually the same.

#### 1. Check for existing lock files.

List existing files in the `.lock` directory:

```bash
> ls -l /uufs/chpc.utah.edu/common/home/u0791983/links/measurements/pipeline/.lock
-rw-rw-r--+ 1 u0791983 lin 0 Sep 24 12:01 fru.lock
-rw-rw-r--+ 1 u0791983 lin 0 Sep 24 20:21 wbb.lock
```

We see that `fru` and `wbb` are currently running. Note the timestamp - looks like `fru` started running 8 hours earlier and never completed. Let's fix it.

#### 2. Kill the process that failed to update a given site (if it exists).

Before delete the lock file to allow site processing to continue, we have to be sure there aren't any existing processes still attempting to connect to the site.

You can list current processes with `ps -u u0791084 -f` (replacing with your username) -

```bash
>  ps -u u0791084 -f
UID        PID  PPID  C STIME TTY          TIME CMD
u0791084 41654 41648  0 20:15 ?        00:00:00 /bin/sh -c nice /uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/process_data.sh &> /uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/log.txt
u0791084 43417 36600  4 20:15 ?        00:00:02 /uufs/chpc.utah.edu/common/home/lin-group12/software/local/R/4.0.3/lib64/R/bin/exec/R --no-echo --no-restore --file=run/wbb.r
u0791983 43823 1      5 12:16 ?        00:12:35 /uufs/chpc.utah.edu/common/home/lin-group12/software/local/R/4.0.3/u0791084/R/bin/exec/R --no-echo --no-restore --file=run/fru.r
...
```

This shows all of the processes running under our user account. We see the `process_data.sh` script running as expected, as well as the `run/fru.r` and `run/wbb.r` scripts that it spawned to update the datasets. Since we identified that we need to fix the `fru` site, we kill the `PID` from the `run/fru.r` process.

```bash
> ps -u u0791084 -f | grep fru.r
u0791084 54474 52478 58 20:26 ?        00:00:02 /uufs/chpc.utah.edu/common/home/lin-group12/software/local/R/4.0.3/lib64/R/bin/exec/R --no-echo --no-restore --file=run/fru.r

> kill 54474
```

Confirm that the process is successfully stopped with `ps` again.

#### 3. Remove the old lock file

Now that we're sure there won't be concurrency problems, we delete the old lock file to allow the processing to run again.

```bash
> rm /uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/.lock/fru.lock
```

Problem solved! We can let the cronjob schedule future executions, or run the processing ourselves by executing the `run/fru.r` script directly.

```bash
> Rscript run/fru.r
Rscript run/fru.r
Run: fru/lgr_ugga 2021-09-25 02:28:54
[1] "loading data/fru/lgr_ugga/raw/2021-09-23/gga_2021-09-23_f0000.txt"
[1] "loading data/fru/lgr_ugga/raw/2021-09-24/gga_2021-09-24_f0000.txt"
New data:
tibble [10,591 × 23] (S3: spec_tbl_df/tbl_df/tbl/data.frame)
 $ Time_UTC    : POSIXct[1:10591], format: "2021-09-23 21:44:58" "2021-09-23 21:45:08" ...
 $ CH4_ppm     : num [1:10591] 1.97 1.97 1.97 1.97 1.97 ...
 $ CH4_ppm_sd  : num [1:10591] 0.000586 0.000588 0.000352 0.000581 0.000378 ...
 $ H2O_ppm     : num [1:10591] 6003 5927 5966 5972 6018 ...
 $ H2O_ppm_sd  : num [1:10591] 21.3 18.5 27.7 25.5 20.9 ...
 $ CO2_ppm     : num [1:10591] 411 411 410 410 410 ...
 $ CO2_ppm_sd  : num [1:10591] 0.249 0.201 0.264 0.253 0.198 ...
 $ CH4d_ppm    : num [1:10591] 1.98 1.98 1.98 1.98 1.98 ...
 $ CH4d_ppm_sd : num [1:10591] 0.00057 0.000615 0.000383 0.000572 0.00037 ...
 $ CO2d_ppm    : num [1:10591] 413 413 413 413 413 ...
 $ CO2d_ppm_sd : num [1:10591] 0.249 0.205 0.263 0.251 0.195 ...
 $ GasP_torr   : num [1:10591] 140 140 140 140 140 ...
 $ GasP_torr_sd: num [1:10591] 0.017 0.0222 0.0216 0.0156 0.0224 ...
 $ GasT_C      : num [1:10591] 22.9 22.9 22.9 22.9 22.9 ...
 $ GasT_C_sd   : num [1:10591] 0.000429 0.000413 0.000476 0.000339 0.000224 ...
 $ AmbT_C      : num [1:10591] 24.9 24.9 24.8 24.8 24.8 ...
 $ AmbT_C_sd   : num [1:10591] 0.01151 0.00339 0.00763 0.00708 0.01091 ...
 $ RD0_us      : num [1:10591] 9.47 9.47 9.47 9.47 9.47 ...
 $ RD0_us_sd   : num [1:10591] 0.000878 0.001605 0.001102 0.001396 0.001087 ...
 $ RD1_us      : num [1:10591] 9.23 9.23 9.23 9.23 9.23 ...
 $ RD1_us_sd   : num [1:10591] 0.00348 0.0026 0.00218 0.00352 0.00443 ...
 $ Fit_Flag    : num [1:10591] 3 3 3 3 3 3 3 3 3 3 ...
 $ ID          : chr [1:10591] "~Atmosphere~Atmosphere" "~Atmosphere~Atmosphere" "~Atmosphere~Atmosphere" "~Atmosphere~Atmosphere" ...
...
```
