with
    divvy_bike_2022 as (
        select
            ride_id,
            started_at as start_time,
            ended_at as end_time,
            start_station_name,
            start_station_id,
            end_station_name,
            end_station_id,
            start_lat,
            start_lng,
            end_lat,
            end_lng,
            member_casual as rider_type
        from {{ source("staging", "divvy_2022") }}
    ),

    -- Remove rows with NULL VALUES in start_station_name & end_station_id
    cleaned_data as (
        select *
        from divvy_bike_2022
        where start_station_name IS NOT NULL AND end_station_id IS NOT NULL
    ),

    -- Cast latitude & longitude columns to NUMERIC
    casted_data as (
        select
            ride_id,
            date(start_time) as start_date,
            time(start_time) as start_time,
            date(end_time) as end_date,
            time(end_time) as end_time,
            start_station_name,
            end_station_name,
            cast(start_lat as numeric) as start_latitude,
            cast(start_lng as numeric) as start_longitude,
            cast(end_lat as numeric) as end_latitude,
            cast(end_lng as numeric) as end_longitude,
            rider_type
        from cleaned_data
    ),

    -- Remove ALL capital letters
    filtered_data as (
        select *
        from casted_data
        where
            upper(start_station_name) != start_station_name
            and upper(end_station_name) != end_station_name
    ),

    -- Casing and remove duplicates
    divvy_final_2022 as (
        select
            ride_id,
            start_date,
            start_time,
            end_date,
            end_time,
            lower(start_station_name) as start_station_name,
            lower(end_station_name) as end_station_name,
            start_latitude,
            start_longitude,
            end_latitude,
            end_longitude,
            rider_type,
            row_number() over (partition by ride_id order by start_time) as row_num
        from filtered_data
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
from divvy_final_2022
where row_num = 1
