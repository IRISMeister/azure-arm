import sys
import pandas

# 大元のデータは以下のURLから取得可能。ただしparquet形式。
# https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
# https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2020-01.parquet

if __name__ == '__main__':
    args = sys.argv
    #df = pandas.read_parquet("\\temp\\yellow_tripdata_2020-01.parquet")
    #df.to_csv("\\temp\\yellow_tripdata_2020-01.csv",index=False)
    df = pandas.read_parquet(args[1])
    df.to_csv(args[2],index=False)
