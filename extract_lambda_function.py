import json
import os
import requests
import boto3

# Initialize S3 client
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    AWS Lambda function to extract data using a requests layer.
    Triggered by EventBridge every 1 minute.
    """
    try:
        # Example: Fetching data from a public API
        api_url = "https://api.spotify.com/v1/artists/0TnOYISbd1XYHihMswcfXX/albums" # Placeholder URL
        headers = {
            "Authorization": "Bearer YOUR_SPOTIPY_ACCESS_TOKEN" # Replace with actual token
        }
        response = requests.get(api_url, headers=headers)
        response.raise_for_status() # Raise an exception for HTTP errors

        data = response.json()

        # Define S3 bucket and key
        bucket_name = os.environ.get('S3_BUCKET_NAME', 'your-etl-raw-data-bucket')
        file_key = f"raw_data/{context.aws_request_id}.json"

        # Upload data to S3
        s3.put_object(
            Bucket=bucket_name,
            Key=file_key,
            Body=json.dumps(data, indent=2),
            ContentType='application/json'
        )

        print(f"Successfully extracted data and uploaded to s3://{bucket_name}/{file_key}")

        return {
            'statusCode': 200,
            'body': json.dumps('Data extraction successful!')
        }
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from API: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"API request failed: {e}")
        }
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"An unexpected error occurred: {e}")
        }
