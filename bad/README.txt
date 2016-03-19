Instructions for LAIR/UATAQ bad data definitions
Ben Fasoli

Time format: 2014-12-13 15:52:40.444
             YYYY-MM-DD HH:MM:SS.SSS
Time Zone:   UTC
Header:      t_start,t_end,miu_old,miu_new,comment

t_start/t_end: Time to start and end slicing the data.
miu_old: numeric value of the standard values to match or "all" to match all data within the given time period.
miu_new: numeric value to replace the matched value with or "NA" to remove all matched data.
comment: user comment about why data is being removed. DO NOT INCLUDE COMMAS in the comment.
