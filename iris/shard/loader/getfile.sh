#!/bin/bash

wget https://data.cityofnewyork.us/api/views/755u-8jsi/rows.csv?accessType=DOWNLOAD -O taxi_zones.csv
wget https://data.cityofnewyork.us/api/views/kxp8-n2sj/rows.csv?accessType=DOWNLOAD -O 2020_Yellow_Taxi_Trip_Data.csv

head 2020_Yellow_Taxi_Trip_Data.csv -n 101 > 100.csv
head 2020_Yellow_Taxi_Trip_Data.csv -n 100001 > 100K.csv
head 2020_Yellow_Taxi_Trip_Data.csv -n 10000001 > 10M.csv

# need to convert date format into which IRIS can understand(I picked ODBC format for max. safety).
# can't use panda because input files are kind of dirty. (missing values)
python3 conv.py 100.csv
python3 conv.py 100K.csv
python3 conv.py 10M.csv
python3 conv.py 2020_Yellow_Taxi_Trip_Data.csv

ADMINHOME=/home/$ADMINUSER
mv data/*.csv $ADMINHOME/
chown $ADMINUSER:$ADMINUSER $ADMINHOME/*.csv