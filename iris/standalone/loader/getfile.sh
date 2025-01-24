#!/bin/bash

# 1年分なので大きい。2.3GBほど。2400万件。
wget https://data.cityofnewyork.us/api/views/kxp8-n2sj/rows.csv?accessType=DOWNLOAD -O 2020_Yellow_Taxi_Trip_Data.csv
touch _getfiles_wget_done_

head 2020_Yellow_Taxi_Trip_Data.csv -n 101 > 100.csv
head 2020_Yellow_Taxi_Trip_Data.csv -n 100001 > 100K.csv
head 2020_Yellow_Taxi_Trip_Data.csv -n 10000001 > 10M.csv
touch _getfiles_head_done_

# need to convert date format into which IRIS can understand(I picked ODBC format for max. safety).
# can't use panda because input files are kind of dirty. (missing values)
python3 conv.py 100.csv
python3 conv.py 100K.csv
python3 conv.py 10M.csv
python3 conv.py 2020_Yellow_Taxi_Trip_Data.csv

touch _getfiles_conv_done_