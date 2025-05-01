import json
import os
import boto3
import uuid
import fitz  # PyMuPDF
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source

# Initialize global variables
logger = Logger()

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Get environment variables
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET')
METADATA_TABLE = os.environ.get('METADATA_TABLE')

# Get DynamoDB table
metadata_table = dynamodb.Table(METADATA_TABLE)

def split_pdf(document_data: bytes, document_id: str) -> List[Dict[str, Any]]:
    """
    Split a PDF document into individual pages and save them to S3.
    
    Args:
        document_data: The PDF document as bytes
        document_id: The unique identifier for the document
        
    Returns:
        List of dictionaries with information about each page
    """
    pages = []
    
    try:
        # Open the PDF document
        pdf_document = fitz.open(stream=document_data, filetype="pdf")
        total_pages = len(pdf_document)
        
        logger.info(f"Processing document {document_id} with {total_pages} pages")
        
        # Process each page
        for page_num in range(total_pages):
            # Extract the page
            page = pdf_document[page_num]
            
            # Create a new PDF with just this page
            output_pdf = fitz.open()
            output_pdf.insert_pdf(pdf_document, from_page=page_num, to_page=page_num)
            
            # Save the individual page to a buffer
            page_buffer = output_pdf.write()
            
            # Generate a page ID
            page_id = f"{document_id}_page_{page_num + 1}"
            
            # Upload the page to S3
            output_key = f"processing/{document_id}/{page_id}.pdf"
            s3_client.put_object(
                Bucket=OUTPUT_BUCKET,
                Key=output_key,
                Body=page_buffer,
                ContentType='application/pdf'
            )
            
            # Extract text from the page
            text = page.get_text()
            
            # Store metadata in DynamoDB
            timestamp = datetime.now().isoformat()
            metadata_table.put_item(
                Item={
                    'documentId': document_id,
                    'pageNumber': page_num + 1,
                    'pageId': page_id,
                    'totalPages': total_pages,
                    's3Key': output_key,
                    'status': 'PENDING',
                    'textCharCount': len(text),
                    'created': timestamp,
                    'lastUpdated': timestamp
                }
            )
            
            # Add page info to result
            pages.append({
                'documentId': document_id,
                'pageNumber': page_num + 1,
                'pageId': page_id,
                'totalPages': total_pages,
                's3Key': output_key,
                'status': 'PENDING'
            })
            
            # Close the output PDF
            output_pdf.close()
        
        # Close the input PDF
        pdf_document.close()
        
    except Exception as e:
        logger.error(f"Error splitting PDF: {str(e)}")
        raise
    
    return pages

def process_image(image_data: bytes, document_id: str, content_type: str) -> List[Dict[str, Any]]:
    """
    Process an image document and save it to S3.
    
    Args:
        image_data: The image document as bytes
        document_id: The unique identifier for the document
        content_type: The content type of the image
        
    Returns:
        List with a single dictionary containing information about the image
    """
    try:
        # Generate a page ID
        page_id = f"{document_id}_page_1"
        
        # Get file extension from content type
        file_ext = content_type.split('/')[-1]
        if file_ext == 'jpeg':
            file_ext = 'jpg'
            
        # Upload the image to S3
        output_key = f"processing/{document_id}/{page_id}.{file_ext}"
        s3_client.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=image_data,
            ContentType=content_type
        )
        
        # Store metadata in DynamoDB
        timestamp = datetime.now().isoformat()
        metadata_table.put_item(
            Item={
                'documentId': document_id,
                'pageNumber': 1,
                'pageId': page_id,
                'totalPages': 1,
                's3Key': output_key,
                'status': 'PENDING',
                'created': timestamp,
                'lastUpdated': timestamp
            }
        )
        
        # Return page info
        return [{
            'documentId': document_id,
            'pageNumber': 1,
            'pageId': page_id,
            'totalPages': 1,
            's3Key': output_key,
            'status': 'PENDING'
        }]
    
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise

def process_text(text_data: bytes, document_id: str) -> List[Dict[str, Any]]:
    """
    Process a text document and save it to S3.
    
    Args:
        text_data: The text document as bytes
        document_id: The unique identifier for the document
        
    Returns:
        List with a single dictionary containing information about the text document
    """
    try:
        # Generate a page ID
        page_id = f"{document_id}_page_1"
        
        # Upload the text to S3
        output_key = f"processing/{document_id}/{page_id}.txt"
        s3_client.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=text_data,
            ContentType='text/plain'
        )
        
        # Store metadata in DynamoDB
        timestamp = datetime.now().isoformat()
        metadata_table.put_item(
            Item={
                'documentId': document_id,
                'pageNumber': 1,
                'pageId': page_id,
                'totalPages': 1,
                's3Key': output_key,
                'status': 'PENDING',
                'textCharCount': len(text_data),
                'created': timestamp,
                'lastUpdated': timestamp
            }
        )
        
        # Return page info
        return [{
            'documentId': document_id,
            'pageNumber': 1,
            'pageId': page_id,
            'totalPages': 1,
            's3Key': output_key,
            'status': 'PENDING'
        }]
    
    except Exception as e:
        logger.error(f"Error processing text: {str(e)}")
        raise

@logger.inject_lambda_context(log_event=True)
@event_source(data_class=S3Event)
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler to process documents from S3 and split them into pages if needed.
    
    Args:
        event: The Lambda event object containing S3 event details
        context: The Lambda context
        
    Returns:
        Dictionary with information about the processed document
    """
    try:
        # Extract information from the event
        if isinstance(event, S3Event):
            # S3 event via decorator
            s3_event = event.records[0].s3
            bucket = s3_event.bucket.name
            key = s3_event.object.key
        elif 'Records' in event:
            # S3 trigger event directly
            s3_event = event['Records'][0]['s3']
            bucket = s3_event['bucket']['name']
            key = s3_event['object']['key']
        elif 'bucket' in event and 'key' in event:
            # Direct invocation with bucket and key
            bucket = event.get('bucket')
            key = event.get('key')
        else:
            raise ValueError("Invalid event structure: missing bucket or key information")
            
        logger.info(f"Processing document from bucket: {bucket}, key: {key}")
        
        # Check if this is from the uploads folder
        if not key.startswith('uploads/'):
            logger.info(f"Skipping document not in uploads folder: {key}")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Document not in uploads folder, skipping',
                    'bucket': bucket,
                    'key': key
                })
            }
            
        # Generate a document ID
        document_id = str(uuid.uuid4())
        
        # Get the document from S3
        try:
            response = s3_client.get_object(Bucket=bucket, Key=key)
            content_type = response.get('ContentType', 'application/octet-stream')
            document_data = response['Body'].read()
        except Exception as e:
            logger.error(f"Error retrieving document from S3: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': f'Error retrieving document from S3: {str(e)}',
                    'bucket': bucket,
                    'key': key
                })
            }
        
        # Process the document based on its type
        try:
            if content_type == 'application/pdf':
                pages = split_pdf(document_data, document_id)
            elif content_type.startswith('image/'):
                pages = process_image(document_data, document_id, content_type)
            elif content_type == 'text/plain' or content_type == 'application/txt':
                pages = process_text(document_data, document_id)
            else:
                logger.warning(f"Unsupported content type: {content_type}, treating as text")
                pages = process_text(document_data, document_id)
        except Exception as e:
            logger.error(f"Error processing document: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': f'Error processing document: {str(e)}',
                    'bucket': bucket,
                    'key': key
                })
            }
            
        # Store document metadata
        timestamp = datetime.now().isoformat()
        original_document_key = f"original/{document_id}/{os.path.basename(key)}"
        
        # Copy the original document
        try:
            s3_client.copy_object(
                Bucket=OUTPUT_BUCKET,
                Key=original_document_key,
                CopySource={'Bucket': bucket, 'Key': key}
            )
        except Exception as e:
            logger.error(f"Error copying original document: {str(e)}")
            # Continue processing, as this is not critical
        
        # Store document summary in DynamoDB
        try:
            metadata_table.put_item(
                Item={
                    'documentId': document_id,
                    'pageNumber': 0,  # Special page number 0 for the entire document
                    'originalKey': key,
                    'originalBucket': bucket,
                    'contentType': content_type,
                    'totalPages': len(pages),
                    'status': 'PROCESSING',
                    'created': timestamp,
                    'lastUpdated': timestamp,
                    'storedKey': original_document_key
                }
            )
        except Exception as e:
            logger.error(f"Error storing document metadata: {str(e)}")
            # Continue processing, as we've already processed the document
        
        # Return the processing result
        return {
            'statusCode': 200,
            'body': json.dumps({
                'documentId': document_id,
                'originalKey': key,
                'contentType': content_type,
                'totalPages': len(pages),
                'pages': pages
            })
        }
            
    except Exception as e:
        logger.error(f"Unhandled error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Unhandled error: {str(e)}'
            })
        } 