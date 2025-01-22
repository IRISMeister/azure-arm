sudo su -
cd /var/lib/waagent/custom-script/download/0

# csvファイルのありか
ls _getfiles*

日付フォーマット変換前
ls *.csv
日付フォーマット変換後
ls /var/tmp/data/

# データのロード(msvm0で実行すること)
iris session iris -U%SYS "##class(Silent.Installer).LoadCSV()"
あるいは
iris session iris -U%SYS 
%SYS> d ##class(Silent.Installer).LoadCSV("NYTaxi.RowRides","/var/tmp/data/10M.csv")
%SYS> d ##class(Silent.Installer).LoadCSV("NYTaxi.ColumnRides","/var/tmp/data/10M.csv")
%SYS> d ##class(Silent.Installer).LoadCSV("NYTaxi.ColumnRides2","/var/tmp/data/10M.csv")

LOAD BULK DATA FROM FILE '/var/tmp/data/10M.csv' INTO NYTaxi.RowRides (VendorID,tpep_pickup_datetime,tpep_dropoff_datetime,passenger_count,trip_distance,RatecodeID,store_and_fwd_flag,PULocationID,DOLocationID,payment_type,fare_amount,extra,mta_tax,tip_amount,tolls_amount,improvement_surcharge,total_amount,congestion_surcharge) USING {"from": {"file": {"columnseparator":",", "header": true,"charset": "UTF-8" }}}
