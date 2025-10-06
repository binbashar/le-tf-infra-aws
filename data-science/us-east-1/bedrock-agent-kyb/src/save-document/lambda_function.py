import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Minimal placeholder - business logic in T-010"""
    logger.info(f"Event: {json.dumps(event)}")
    return {"statusCode": 200, "body": json.dumps({"status": "not_implemented"})}
