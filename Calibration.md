# Calibration

Data from UUCON measurement sites with a Licor 6262 or Licor 7000 on-site are calibrated every 2 h using the three reference gases, while sites with a LGR UGGA are calibrated every 3 h. Since the Li-6262s are near linear through the range of atmospheric observations and calibration gases, each standard of known mole fraction is linearly interpolated between two consecutive calibration periods to represent the drift in the measured standards over time. Ordinary least squares regression is then applied to the interpolated reference values, and the linear coefficients are used to correct the observations. The linear slope, intercept, and fit statistics are returned for each observation for diagnostic purposes. See [Bares et al., 2019](https://doi.org/10.5194/essd-11-1291-2019) for more details.

## Gas Identification

To differentiate data between atmospheric air and reference gas measurements, we use the following `ID` convention:
| ID  | Description                                                |
| --- | ---------------------------------------------------------- |
| ≥0  | Reference gas measurement -- value indicates concentration |
| -10 | Atmospheric air measurement                                |
| -99 | System flush                                               |

## Column naming conventions for calibrated data files

### Licor 6262 IRGA

| Column Name     | Description                                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| `Time_UTC`      | Time in UTC                                                                         |
| `CO2d_ppm_cal`  | The calibrated concenctration of DRY CO2 in parts per million                       |
| `CO2d_ppm_meas` | The uncalibrated concentraion of DRY CO2 in parts per million                       |
| `CO2d_m`        | The slope of the calibration applied                                                |
| `CO2d_b`        | The y-intercept of the calibration applied                                          |
| `CO2d_n`        | The number of calibration tanks used in the calibration applied                     |
| `CO2d_rsq`      | The R^2 value derived from the slope of the calibration applied                     |
| `CO2d_rmse`     | The root mean squared error value derived from the slope of the calibration applied |
| `ID_CO2`        | ID of CO2 being measured (-10(ambient), -99(flushing), Standard tank concentration) |
| `QAQC_Flag`     | Automated QC flagging. See table "QAQC flagging conventions"                        |

### Los Gatos Research UGGA

| Column Name     | Description                                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| `Time_UTC`      | Time in UTC                                                                         |
| `CO2d_ppm_cal`  | The calibrated concenctration of DRY CO2 in parts per million                       |
| `CO2d_ppm_meas` | The uncalibrated concentraion of DRY CO2 in parts per million                       |
| `CO2d_m`        | The slope of the calibration for CO2                                                |
| `CO2d_b`        | The y-intercept of the calibration for CO2                                          |
| `CO2d_n`        | The number of calibration tanks used in the calibration for CO2                     |
| `CO2d_rsq`      | The R^2 value derived from the slope of the calibration for CO2                     |
| `CO2d_rmse`     | The root mean squared error value derived from the slope of the calibration for CO2 |
| `ID_CO2`        | ID of CO2 being measured (-10(ambient), -99(flushing), Standard tank concentration) |
| `CH4d_ppm_cal`  | The calibrated concenctration of DRY CH4 in parts per million                       |
| `CH4d_ppm_meas` | The uncalibrated concentraion of DRY CH4 in parts per million                       |
| `CH4d_m`        | The slope of the calibration for CH4                                                |
| `CH4d_b`        | The y-intercept of the calibration for CH4                                          |
| `CH4d_n`        | The number of calibration tanks used in the calibration for CH4                     |
| `CH4d_rsq`      | The R^2 value derived from the slope of the calibration for CH4                     |
| `CH4d_rmse`     | The root mean squared error value derived from the slope of the calibration for CH4 |
| `ID_CH4`        | ID of CH4 being measured (-10(ambient), -99(flushing), Standard tank concentration) |
| `QAQC_Flag`     | Automated QC flagging. See table "QAQC flagging conventions"                        |