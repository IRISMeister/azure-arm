create table NYTaxi.ColumnRides (
    VendorID int, 
    tpep_pickup_datetime timestamp,
    tpep_dropoff_datetime timestamp,
    passenger_count int,
    trip_distance double,
    RatecodeID int,
    store_and_fwd_flag VARCHAR(25),
    PULocationID int,
    DOLocationID int,
    payment_type int,
    fare_amount double,
    extra double,
    mta_tax double,
    tip_amount double,
    tolls_amount double,
    improvement_surcharge double,
    total_amount double,
    congestion_surcharge double,
    SHARD
) WITH STORAGETYPE = COLUMNAR
GO
CREATE Bitmap Index PULocationID On NYTaxi.ColumnRides(PULocationID) 
GO
CREATE Bitmap Index passenger_count On NYTaxi.ColumnRides(passenger_count)
GO
CREATE Index pickup_time On NYTaxi.ColumnRides(tpep_pickup_datetime)
GO


