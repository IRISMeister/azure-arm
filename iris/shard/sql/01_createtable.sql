CREATE TABLE green_tripdata (
    VendorID VARCHAR(32767), 
    lpep_pickup_datetime TimeStamp, 
    Lpep_dropoff_datetime TimeStamp, 
    Store_and_fwd_flag VARCHAR(1), 
    RateCodeID Integer, 
    Pickup_longitude numeric(18,15), 
    Pickup_latitude numeric(18,15), 
    Dropoff_longitude numeric(18,15), 
    Dropoff_latitude numeric(18,15), 
    Passenger_count Integer, 
    Trip_distance numeric(18,2), 
    Fare_amount numeric(18,2), 
    Extra numeric(18,2), 
    MTA_tax numeric(18,2), 
    Tip_amount numeric(18,2), 
    Tolls_amount numeric(18,2), 
    Ehail_fee varchar(100), 
    improvement_surcharge numeric(18,2), 
    Total_amount numeric(18,2), 
    Payment_type Integer, 
    Trip_type varchar(10),
    shard
    
)
GO
CREATE INDEX idx_VendorID ON green_tripdata(VendorID)
GO
CREATE INDEX idx_lpep_pickup_datetime ON green_tripdata(lpep_pickup_datetime)
GO
CREATE INDEX idx_Lpep_dropoff_datetime ON green_tripdata(Lpep_dropoff_datetime)
GO
CREATE BITMAP INDEX idxbm_lpep_pickup_datetime on green_tripdata(lpep_pickup_datetime)
GO
CREATE INDEX idx_Payment_type ON green_tripdata(Payment_type)
GO
CREATE INDEX idx_Trip_type ON green_tripdata(Trip_type)
GO
CREATE INDEX idx_RateCodeID ON green_tripdata(RateCodeID)
GO
