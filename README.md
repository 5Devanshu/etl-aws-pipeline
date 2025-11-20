# ETL Pipeline for Music Data Analytics

This project implements a robust and automated Extract, Transform, Load (ETL) pipeline designed to ingest, process, and analyze Spotify artist and track data. Leveraging serverless AWS components and Snowflake, this pipeline provides real-time insights into music listening patterns and trends.

## Architecture Diagram
Here's a visual representation of the ETL pipeline:

![ETL Pipeline Diagram](https://www.plantuml.com/plantuml/png/TLJ1RkCs4BtpAmO9q2OeZ2ODkeSSYbMyKf72kt4iBT82Uw4bscOjaIf9nLMB0ls8Vc6_f8-aBMczwCdMpBp7cVU6V6iTDwvhQkQagmMbnOAMiXMrL8B-_ViVobljvAQdzvsL9RtZZbEYUDqxMLgwEaYte-TEbljSRdVkcZ6xbwhbXZTKwgRLIYYNknxCHfIEgsqj9YLsnojza6fB6rxRQSReJbMbDaeOklrkaaYCqOUvhhMXovkRDs_cSyQ-fgHqsbZ6_GzTvELEL5qjp2TrbRwYWmSZgwsulY1kANtmWFHt9mpce6Jvo8RM08tZ-Z30uQlj8p1VFXMFsIzqcTvctsTfEFObfmNlXM4jB_Ty2m8Vkig5UHMc5jR6D0Z-P3GgGXSutw1Rf9jrnN5KsxkTLlGD6V5R9wopL0Va9tMQfY81qfvkgP4gZlBpudFM_8vM_40FNRaN3gG67p_bJn_0fIelynyeF4vpjqfUFaSNXYkxqQQPT0KS7rifZDnkXK4hwnuCjFnO1B9YzMKZ0nkgXuRS90W_CQdxjhIlfvQA5VlBwvehVTZKV2_ErHqINmWw69exL4Q-8landLP5V8lrHYkySte6JQ0rROnko7fWx6Jvk3m3UbaBleQbW9xKj72cuH42DOl_aLDK8zHVjrd4KQChKTi8pv9vaP_rwepWZQMlWBPx3vQgDA914cF6pgLMH-sALPgypwDymmMTRdRISBW_kQmWVCVjRgsvgN3AY8gCppbTPbbsbzw0CbxyhDO7bZxGRFQ3tpswft4tNLmDXhZF3xVbdZBXoXrnuwHrECOPc4aL-8RQi8keV37I2JejBOjX5FZzGjhUtJ-jVyL4SmZZH7M_x1ppgSXHh0QAwPg5arX8eouk11Gg7VGcs4nWXmaR29HPBK1ps0BN9k2eCePZpXYEtqBmABRjWCGjXv4-EeAG84vSxxXdOAOwQw3eg7YV6jaQNmbeSnsBQ5pwZ2jRvwu-ng1fyyzvyq0wyIdljlB6aDyUdOKOVhR1qVCPyuEnv2Q794tcoaQx2AtFDXAh8CxF8NujDe2zMaJw-3wFUt6-apyHd1rVLEQ4m2umlQy7zttFEeMSlRS2URYc5Erf3uH1UwCCCX4AL_RZ-8zjR_EkQ-Zy0)

## Architecture Overview
The pipeline consists of the following key components:
1.  **Data Extraction:** An AWS Lambda function, triggered by EventBridge, extracts raw Spotify data using the Spotipy library and a `requests` layer.
2.  **Raw Data Storage:** Extracted raw data is stored in an S3 bucket, serving as the landing zone.
3.  **Data Transformation:** An AWS Lambda function, triggered by S3 PUT events (upon raw data arrival), transforms the data using a `pandas` layer.
4.  **Transformed Data Storage:** Transformed data is stored in another S3 bucket, ready for loading into Snowflake.
5.  **Data Loading & Warehousing:** Snowflake is used for data warehousing, with Snowpipe and external stages configured to automatically ingest data from S3.
6.  **Analytics & Incremental Processing:** Star-schema models are designed within Snowflake, with streams and tasks enabling efficient incremental ingestion and analytics.
## Features:
-   **Automated Spotify Data Ingestion:** Utilizes AWS Lambda and the Spotipy library to connect to the Spotify API and extract artist/track data.
-   **Event-Driven Extraction:** An **Extract Lambda Function** (deployed with a `requests` layer for external API calls) is scheduled by AWS EventBridge to run every 1 minute, ensuring timely data collection.
-   **Robust Data Transformation:** A **Transform Lambda Function** (utilizing a `pandas` layer for powerful data manipulation) processes raw data from S3, flattening JSON structures, selecting relevant fields, and performing necessary cleaning. This function is automatically triggered by new raw data files arriving in S3.
-   **Automated Snowflake Loading:** Employs Snowpipe and event-based S3 triggers to seamlessly load transformed data into Snowflake, minimizing latency and manual intervention.
-   **Star-Schema Data Modeling:** Designed for optimal analytical performance, enabling easy querying for listening patterns, genre popularity, and trend analysis.
-   **Incremental Ingestion:** Implemented within Snowflake using streams and tasks to process only new or changed data, significantly reducing compute costs and improving overall efficiency.
-   **Snowflake Infrastructure as Code:** The `snowflake_setup.sql` script provides all necessary SQL commands to set up databases, schemas, external stages for S3, Snowpipes, tables for raw and transformed data, and tasks for automated incremental loading.

## Technologies Used:
-   **Python:** Primary language for Lambda functions and data processing.
-   **AWS Lambda:** Serverless compute for event-driven data extraction and transformation.
-   **Amazon S3:** Scalable and durable storage for raw and transformed data.
-   **Snowflake:** Cloud data warehouse for robust analytics and data management.
-   **Spotipy:** Python library for interacting with the Spotify Web API.
-   **AWS EventBridge:** Schedules the data extraction Lambda function.
-   **Pandas:** Python library for data manipulation within the transform Lambda.
-   **SQL:** For defining Snowflake schemas, tables, stages, pipes, streams, and tasks.

## Setup and Deployment:
1.  **AWS Setup:**
    *   Create two S3 buckets: one for raw data (e.g., `your-etl-raw-data-bucket`) and one for transformed data (e.g., `your-etl-transformed-data-bucket`).
    *   Configure IAM roles for Lambda functions with appropriate S3 and CloudWatch permissions.
    *   Deploy `extract_lambda_function.py` with a `requests` Lambda Layer. Configure an EventBridge rule to trigger it every 1 minute.
    *   Deploy `transform_lambda_function.py` with a `pandas` Lambda Layer. Configure an S3 event notification on the raw data bucket to trigger it for `s3:ObjectCreated:Put` events.
    *   Ensure your AWS credentials (or IAM role) have necessary permissions for S3 and EventBridge.
2.  **Snowflake Setup:**
    *   Execute the SQL commands in `snowflake_setup.sql` within your Snowflake environment. Remember to replace placeholders like `YOUR_AWS_ACCESS_KEY_ID`, `YOUR_AWS_SECRET_ACCESS_KEY`, and `YOUR_WAREHOUSE_NAME`.
    *   Ensure the Snowflake user has permissions to create databases, schemas, stages, pipes, and tasks.
3.  **Spotify API Access:**
    *   Obtain a Spotify Developer account and generate a client ID and client secret to get an access token for Spotipy. Update the `YOUR_SPOTIPY_ACCESS_TOKEN` placeholder in `extract_lambda_function.py`.

## GitHub:
https://github.com/5Devanshu/etl-aws-pipeline
