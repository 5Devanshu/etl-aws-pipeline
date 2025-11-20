import json
import os
import pandas as pd
import boto3

# Initialize S3 client
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    AWS Lambda function to transform data using a pandas layer.
    Triggered by S3 PUT events in the raw data bucket.
    """
    try:
        # Get the S3 bucket and key from the event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        file_key = event['Records'][0]['s3']['object']['key']

        print(f"Processing s3://{bucket_name}/{file_key}")

        # Download the raw data from S3
        response = s3.get_object(Bucket=bucket_name, Key=file_key)
        raw_data = json.loads(response['Body'].read().decode('utf-8'))

        # Example: Flattening and transforming data using pandas
        # Assuming raw_data is a list of dictionaries or similar structure
        if isinstance(raw_data, dict) and 'items' in raw_data:
            df = pd.json_normalize(raw_data['items'])
        else:
            df = pd.DataFrame(raw_data)


        # Perform some transformations (e.g., select columns, rename, clean data)
        # Placeholder for actual transformation logic based on Spotify data structure
        transformed_df = df[['id', 'name', 'type', 'release_date']].copy()
        transformed_df.rename(columns={'id': 'album_id', 'name': 'album_name'}, inplace=True)
        # Add more complex transformations as needed

        # Define S3 bucket and key for transformed data
        transformed_bucket_name = os.environ.get('S3_TRANSFORMED_BUCKET_NAME', 'your-etl-transformed-data-bucket')
        transformed_file_key = f"transformed_data/{os.path.basename(file_key)}"

        # Upload transformed data to S3
        s3.put_object(
            Bucket=transformed_bucket_name,
            Key=transformed_file_key,
            Body=transformed_df.to_json(orient='records', indent=2),
            ContentType='application/json'
        )

        print(f"Successfully transformed data and uploaded to s3://{transformed_bucket_name}/{transformed_file_key}")

        return {
            'statusCode': 200,
            'body': json.dumps('Data transformation successful!')
        }
    except Exception as e:
        print(f"An unexpected error occurred during transformation: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"An unexpected error occurred: {e}")
        }
