
import os
import boto3
from botocore.exceptions import ClientError, BotoCoreError

PRIMARY_BUCKET = os.environ["PRIMARY_BUCKET"]
SECONDARY_BUCKET = os.environ["SECONDARY_BUCKET"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

sns = boto3.client("sns")


def check_bucket(bucket_name):
    try:
        s3 = boto3.client("s3")

        s3.head_bucket(Bucket=bucket_name)

        return True

    except (ClientError, BotoCoreError) as error:
        print(f"Bucket check failed: {bucket_name}: {error}")
        return False


def lambda_handler(event, context):
    primary_ok = check_bucket(PRIMARY_BUCKET)
    secondary_ok = check_bucket(SECONDARY_BUCKET)

    print(f"Primary bucket healthy: {primary_ok}")
    print(f"Secondary bucket healthy: {secondary_ok}")

    if not primary_ok or not secondary_ok:
        message = (
            "Self-Healing Cloud Storage Alert\n\n"
            f"Primary bucket: {PRIMARY_BUCKET}\n"
            f"Primary status: {'HEALTHY' if primary_ok else 'FAILED'}\n\n"
            f"Secondary bucket: {SECONDARY_BUCKET}\n"
            f"Secondary status: {'HEALTHY' if secondary_ok else 'FAILED'}"
        )

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="AWS Storage Health Alert",
            Message=message
        )

    return {
        "statusCode": 200,
        "primary_bucket_healthy": primary_ok,
        "secondary_bucket_healthy": secondary_ok
    }
