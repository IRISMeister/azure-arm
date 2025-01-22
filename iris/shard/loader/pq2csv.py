import sys
import pandas

#df = pandas.read_parquet(args[1])
df = pandas.read_parquet("\\temp\\yellow_tripdata_2010-01.parquet")
# index=Falseで左端の行番号を非表示にできる
df.to_csv("\\temp\\yellow_tripdata_2010.csv",index=False)