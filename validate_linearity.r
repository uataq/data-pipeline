
library(data.table)
library(tidyverse)

lapply(dir('src', full.names = T), source)

lgn <- rbindlist(lapply(dir('../data/lgn/licor_6262/qaqc/', full.names = T), fread))
lgn$Time_UTC <- as.POSIXct(lgn$Time_UTC, tz = 'UTC')

cals <- lgn %>%
  filter(ID_CO2 > 0) %>%
  select(ID_CO2, CO2d_ppm)

mod_linear <- lm(CO2d_ppm ~ ID_CO2, data = cals)
mod_poly <- lm(CO2d_ppm ~ poly(ID_CO2, 2), data = cals)

tanks <- unique(cals$ID_CO2)
df_linear <- data.frame(ID_CO2 = tanks)
df_linear$CO2d_ppm <- predict(mod_linear, df_linear)
df_poly <- data.frame(ID_CO2 = tanks)
df_poly$CO2d_ppm <- predict(mod_poly, df_linear)


cals$diff = with(cals, CO2d_ppm - ID_CO2)
df_linear$diff = with(df_linear, CO2d_ppm - ID_CO2)
df_poly$diff = with(df_poly, CO2d_ppm - ID_CO2)

linear_rmse <- with(df_linear, sqrt(mean(diff^2)))
poly_rmse <- with(df_poly, sqrt(mean(diff^2)))

ggplot(cals, aes(x = ID_CO2, y = diff, color = as.factor(ID_CO2))) +
  geom_point(alpha = 0.1) +
  geom_line(data = df_linear, color = 'red', alpha = 0.5) +
  geom_line(data = df_poly, color = 'blue', alpha = 0.5) +
  theme_classic() +
  labs(color = NULL)

summary(mod_linear)
summary(mod_poly)
