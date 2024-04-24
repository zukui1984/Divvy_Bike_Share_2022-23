{{ config(materialized="table") }}

with
    bike_union as (
        select
            ride_id,
            start_date,
            start_time,
            end_date,
            end_time,
            start_station_name,
            end_station_name,
            start_latitude,
            start_longitude,
            end_latitude,
            end_longitude,
            rider_type
        from {{ ref("stg_divvy_2022") }}

        union all

        select
            ride_id,
            start_date,
            start_time,
            end_date,
            end_time,
            start_station_name,
            end_station_name,
            start_latitude,
            start_longitude,
            end_latitude,
            end_longitude,
            rider_type
        from {{ ref("stg_divvy_2023") }}
    )

select
    ride_id,
    start_date,
    start_time,
    end_date,
    end_time,
    start_station_name,
    end_station_name,
    start_latitude,
    start_longitude,
    end_latitude,
    end_longitude,
    rider_type
from bike_union
