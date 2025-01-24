#!/bin/bash

# pip install pandas pyarrow fastparquet
# 1月ごとのデータになっている。parquet形式。90MBほど。640万件。
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2020-01.parquet -O yellow_tripdata_2020-01.parquet
touch _getfiles_wget_done_

python3 pq2csv.py yellow_tripdata_2020-01.parquet yellow_tripdata_2020-01.csv
touch _getfiles_pq2csv_done_

head yellow_tripdata_2020-01.csv -n 101 > /var/tmp/data/100.csv
head yellow_tripdata_2020-01.csv -n 100001 > /var/tmp/data/100K.csv
head yellow_tripdata_2020-01.csv -n 1000001 > /var/tmp/data/1M.csv
touch _getfiles_head_done_