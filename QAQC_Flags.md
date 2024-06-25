# QAQC Flags

Numeric values are assigned to observations that meet certain automated or human identified criterion. Positive flags are considered passing. The meaning of these identifiers are as follows:

| Flag | Description                                                                       |
| ---- | --------------------------------------------------------------------------------- |
| ↓    | **General**                                                                       |
| 2    | Measurement data filled from backup data recording source                         |
| 1    | Data failed automatic QAQC but manually passed                                    |
| 0    | Data passes all QAQC metrics                                                      |
| -1   | Data manually removed                                                             |
| ↓    | **Calibration**                                                                   |
| -2   | System flush                                                                      |
| -3   | Invalid identifier                                                                |
| -4   | Drift between adjacent reference tank measurements exceeds limit                  |
| -5   | Time elapsed between reference tank measurements exceeds limit                    |
| -6   | Reference tank measurements out of range                                          |
| ↓    | **2B 205**                                                                        |
| -10  | `O3_ppb` measurement out of range (0, 250)                                        |
| -11  | `Flow_CCmin` flow rate out of range (1800, 3000)                                  |
| -12  | `Cavity_T_C` cell temperature out of range (0, 50)                                |
| -13  | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      |
| ↓    | **GPS**                                                                           |
|  20  | position at vehicle storage                                                       |
| -21  | `Fix_Quality` invalid gga fix                                                     |
| -22  | `N_Sat` number of satellites < 4                                                  |
| -23  | `Status` invalid rmc status                                                       |
| -24  | `Time_UTC` recent outage > 5 mins -- warmup period of 1 min                       |
| ↓    | **Licor 6262 IRGA**                                                               |
| -30  | `CO2d_ppm` measurement out of range (0, 3000)                                     |
| -31  | `Flow_mLmin` flow rate out of range (395, 405)                                    |
| -32  | `Cavity_T_C_IRGA` cavity temperature out of range (0, 50)                         |
| -33  | `Cavity_P_kPa_IRGA` cavity pressure out of range (50, 115)                        |
| -34  | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      |
| ↓    | **Licor 7000 IRGA**                                                               |
| -40  | `CO2d_ppm` measurement out of range  (0, 3000)                                    |
| -41  | `Flow_mLmin` flow rate out of range (395, 405)                                    |
| -42  | `Cavity_T_C_IRGA` cavity temperature out of range (0, 55)                         |
| -43  | `Cavity_P_kPa_IRGA` cavity pressure out of range (50, 115)                        |
| -44  | `Time_UTC` recent outage > 1 hour -- warmup period of 2 mins                      |
| ↓    | **Los Gatos Research NO2**                                                        |
| -50  | `NO2_ppb` measurement out of range (0, 1000)                                      |
| -51  | `Cavity_P_torr` cavity pressure out of range (296, 300)                           |
| -52  | `Cavity_T_C` cavity temperature out of range (0, 50)                              |
| -53  | `Time_UTC` recent out > 1 hour -- warmup period of 5 mins                         |
| ↓    | **Los Gatos Research UGGA**                                                       |
| -60  | `CH4d_ppm` measurement out of range  (0, 1000)                                    |
| -61  | `CO2d_ppm` measurement out of range  (0, 3000)                                    |
| -62  | `H2O_ppm` measurement out of range   (0, 30000)                                   |
| -63  | `Cavity_P_torr` cavity pressure out of range (135, 145)                           |
| -64  | `Cavity_T_C` cavity temperature out of range (5, 45)                              |
| -65  | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      |
| ↓    | **Magee AE33**                                                                    |
| -70  | `BC6_ngm3` measurement out of range (0, 100000)                                   |
| -71  | `Flow_Lmin` flow rate out of range (4.9, 5.1)                                     |
| -72  | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      |
| ↓    | **MetOne ES642**                                                                  |
| -80  | `PM2.5_ugm3` measurement out of range  (0, 100000)                                |
| -81  | `Flow_Lmin` flow rate out of range (1.9, 2.1)                                     |
| -82  | `Cavity_RH_pct` cavity humidty out of range (0, 50)                               |
| -83  | `Status` alarm status > 0                                                         |
| -84  | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      |
| ↓    | **Teledyne T200**                                                                 |
| -90  | `NO_ppb` measurement out of range (-3, 20000)                                     |
| -91  | `NO2_ppb` measurement out of range (-3, 20000)                                    |
| -92  | `Flow_CCmin` flow rate out of range (350, 600)                                    |
| -93  | `O3_Flow_CCmin` ozone flow rate out of range (50, 150)                            |
| -94  | `RCel_Pres_inHgA` reaction cell pressure out of range (3, 6)                      |
| -95  | `Moly_T_C` molybdenum converter temperature out of range (305, 325)               |
| -96  | `PMT_T_C` photomultiplier tube temperature out of range (5, 12)                   |
| -97  | `Box_T_C` operating temperature out of range (5, 50)                              |
| -98  | `Time_UTC` recent outage > 2 hours -- warmup period of 1 hour                     |
| ↓    | **Teledyne T300**                                                                 |
| -100 | `CO_ppb` measurement out of range  (0, 100000)                                    |
| -101 | `Flow_CCmin` flow rate out of range (500, 1000)                                   |
| -102 | `Samp_Pres_inHgA` sample pressure out of range (15, 35)                           |
| -103 | `Samp_T_C` sample temperature out of range (10, 100)                              |
| -104 | `Bench_T_C` optical bench temperature out of range (46, 50)                       |
| -105 | `Wheel_T_C` filter wheel temperature out of range (66, 70)                        |
| -106 | `Box_T_C` operating temperature out of range (5, 50)                              |
| -107 | `Time_UTC` recent outage > 2 hours -- warmup period of 1 hour                     |
| ↓    | **Teledyne T400**                                                                 |
| -110 | `O3_ppb` measurement out of range  (0, 10000)                                     |
| -111 | `Flow_CCmin` flow rate out of range (500, 1000)                                   |
| -112 | `Samp_Pres_inHgA` sample pressure out of range (15, 35)                           |
| -113 | `Samp_T_C` sample temperature out of range (10, 50)                               |
| -114 | `Box_T_C` operating temperature out of range (5, 50)                              |
| -115 | `Time_UTC` recent outage > 2 hours -- warmup period of 1 hour                     |
| ↓    | **Teledyne T500u**                                                                |
| -120 | `NO2_ppb` measurement out of range  (0, 1000)                                     |
| -121 | `Samp_Pres_inHgA` sample pressure out of range (15, 35)                           |
| -122 | `Phase_T_C` gas phase chemiluminescence chamber temperature out of range (15, 35) |
| -123 | `Box_T_C` operating temperature out of range (5, 50)                              |
| -124 | `ARef_L_mm` auto reference loss out of range (400, 1100)                          |
| -125 | `Time_UTC` recent outage > 2 hours -- warmup period of 1 hour                     |
| ↓    | **TEOM 1400ab**                                                                   |
| -130 | `PM2.5_ugm3` measurement out of range (0, 300000)                                 |
| -131 | `Time_UTC` recent outage > 1 hour -- warmup period of 5 mins                      | 