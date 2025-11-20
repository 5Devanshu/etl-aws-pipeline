-- Create database and schema
CREATE DATABASE IF NOT EXISTS SPOTIFY_DB;
CREATE SCHEMA IF NOT EXISTS SPOTIFY_DB.RAW_DATA;
CREATE SCHEMA IF NOT EXISTS SPOTIFY_DB.ANALYTICS;

-- Create external stage for S3 raw data
CREATE OR REPLACE STAGE SPOTIFY_DB.RAW_DATA.S3_RAW_STAGE
  URL = 's3://your-etl-raw-data-bucket/raw_data/' -- Replace with your S3 raw data bucket
  CREDENTIALS = (AWS_KEY_ID = 'YOUR_AWS_ACCESS_KEY_ID' AWS_SECRET_KEY = 'YOUR_AWS_SECRET_ACCESS_KEY') -- Replace with your AWS credentials or use IAM role
  FILE_FORMAT = (TYPE = 'JSON');

-- Create external stage for S3 transformed data
CREATE OR REPLACE STAGE SPOTIFY_DB.RAW_DATA.S3_TRANSFORMED_STAGE
  URL = 's3://your-etl-transformed-data-bucket/transformed_data/' -- Replace with your S3 transformed data bucket
  CREDENTIALS = (AWS_KEY_ID = 'YOUR_AWS_ACCESS_KEY_ID' AWS_SECRET_KEY = 'YOUR_AWS_SECRET_ACCESS_KEY') -- Replace with your AWS credentials or use IAM role
  FILE_FORMAT = (TYPE = 'JSON');

-- Create table for raw Spotify data
CREATE OR REPLACE TABLE SPOTIFY_DB.RAW_DATA.SPOTIFY_RAW_ALBUMS (
    RAW_JSON VARIANT
);

-- Create a pipe for raw data (Event-based S3 trigger with Snowpipe)
CREATE OR REPLACE PIPE SPOTIFY_DB.RAW_DATA.SPOTIFY_RAW_ALBUMS_PIPE AUTO_INGEST=TRUE AS
COPY INTO SPOTIFY_DB.RAW_DATA.SPOTIFY_RAW_ALBUMS
FROM @SPOTIFY_DB.RAW_DATA.S3_RAW_STAGE
FILE_FORMAT = (TYPE = 'JSON');

-- Create table for transformed Spotify albums data (example star-schema dimension)
CREATE OR REPLACE TABLE SPOTIFY_DB.ANALYTICS.DIM_ALBUMS (
    ALBUM_ID VARCHAR PRIMARY KEY,
    ALBUM_NAME VARCHAR,
    ALBUM_TYPE VARCHAR,
    RELEASE_DATE DATE,
    LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Example: Create a Stream for CDC / incremental loading into DIM_ALBUMS
CREATE OR REPLACE STREAM SPOTIFY_DB.RAW_DATA.ALBUM_TRANSFORMED_STREAM ON TABLE SPOTIFY_DB.RAW_DATA.SPOTIFY_RAW_ALBUMS;

-- Example: Task to automatically load transformed data into DIM_ALBUMS from stream
CREATE OR REPLACE TASK SPOTIFY_DB.ANALYTICS.LOAD_DIM_ALBUMS
  WAREHOUSE = YOUR_WAREHOUSE_NAME -- Replace with your warehouse name
  SCHEDULE = '5 MINUTE' -- Adjust schedule as needed for incremental loads
WHEN
  SYSTEM$STREAM_HAS_DATA('SPOTIFY_DB.RAW_DATA.ALBUM_TRANSFORMED_STREAM')
AS
INSERT INTO SPOTIFY_DB.ANALYTICS.DIM_ALBUMS (ALBUM_ID, ALBUM_NAME, ALBUM_TYPE, RELEASE_DATE)
SELECT
    t.value:album_id::VARCHAR,
    t.value:album_name::VARCHAR,
    t.value:type::VARCHAR,
    t.value:release_date::DATE
FROM
    SPOTIFY_DB.RAW_DATA.ALBUM_TRANSFORMED_STREAM AS s,
    LATERAL FLATTEN(INPUT => s.RAW_JSON) AS t;

-- Resume the task (tasks are created in suspended state)
ALTER TASK SPOTIFY_DB.ANALYTICS.LOAD_DIM_ALBUMS RESUME;

-- More analytics tables and relationships can be defined here based on the star schema design
