{{ config(
    access='public',

    materialized='s3tables_iceberg',
    schema='s3tables_schema'
) }}

select *
from {{ source('s3tables', 'daily_sales') }}
limit 10
