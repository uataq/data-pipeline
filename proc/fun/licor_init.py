#!/bin/bash/python
import sys
sys.path.append('/uufs/chpc.utah.edu/common/home/u0791983/Python/anaconda/lib/python2.7/site-packages')
from pycampbellcr1000 import CR1000
from datetime import datetime
def crpull(ip, port, table, tstart, tend):
    print('Connecting to device...')
    device = CR1000.from_url('tcp:' + str(ip) + ':' + str(port), timeout=10)

    if len(tstart) > 0:
        tstart = datetime.strptime(tstart, '%Y-%m-%d %H:%M:%S')
        tend = datetime.strptime(tend, '%Y-%m-%d %H:%M:%S')
        print('Pulling data from the ' + table + ' table after ' + str(tstart) + '...')
        rawdata = device.get_data('Dat', tstart, tend)
    else:
        print('Pulling all data from the ' + table + ' table...')
        rawdata = device.get_data('Dat')
        device.bye()

    if len(rawdata) > 0:
        orderedcol = rawdata.filter(('Datetime', 'RecNbr', 'Year', 'jDay', 'HH', 'MM', 'SS',
                                     'batt_volt_Min', 'PTemp_Avg', 'Room_T_Avg', 'IRGA_T_Avg', 
                                     'IRGA_P_Avg', 'MF_Controller_mLmin_Avg', 'PressureVolt_Avg', 
                                     'RH_voltage_Avg', 'Gas_T_Avg', 'rawCO2_Voltage_Avg', 
                                     'rawCO2_Avg', 'rawH2O_Avg', 'ID', 'Program'))
        newdata = orderedcol.to_csv(header=False).split('\r\n')
        return(newdata)
    else:
        return('')
