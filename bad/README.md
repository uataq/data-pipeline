# Instructions for LAIR/UATAQ bad data definitions  
Contact [Ben Fasoli](mailto:benfasoli@gmail.com) with questions.  
A helper utility is available at [air.utah.edu](http://air.utah.edu/s/utilities/find_bad/) for identifying previous failed calibrations.  

**Header**:  t_start,t_end,miu_old,miu_new,comment  

Column        | Details
--------------|-------------------
t_start/t_end | Time to start and end slicing the data. Format as 2014-12-13 15:52:40.444, YYYY-MM-DD HH:MM:SS.SSS in UTC time.
miu_old       | numeric value of the standard values to match or "all" to match all data within the given time period.  
miu_new       | numeric value to replace the matched value with or "NA" to remove all matched data.  
comment       | user comment about why data is being removed. DO NOT INCLUDE COMMAS in the comment.  
