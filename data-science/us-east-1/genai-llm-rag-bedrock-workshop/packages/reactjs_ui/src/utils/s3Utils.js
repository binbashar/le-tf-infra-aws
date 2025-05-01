/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { fetchAuthSession } from 'aws-amplify/auth';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import awsconfig from '../aws-exports';

// Get bucket name from environment variables or config
// This will look for a custom attribute in aws-exports.js or use a fallback name
const INPUT_BUCKET_NAME = awsconfig.document_processing_input_bucket;

/**
 * Upload a file to S3
 * @param {File} file - The file object to upload
 * @returns {Promise<{bucket: string, key: string}>} - The S3 bucket and key where the file was uploaded
 */
export const uploadFileToS3 = async (file) => {
    try {
        // Get AWS credentials from Amplify
        const session = await fetchAuthSession();
        const credentials = session.credentials;
        const region = session.identityId.split(':')[0];
        
        // Create S3 client
        const s3Client = new S3Client({
            region: region,
            credentials: credentials
        });
        
        // Generate a unique key for the file
        const key = `uploads/${Date.now()}_${file.name}`;
        
        // Read the file as an ArrayBuffer
        const fileContent = await readFileAsArrayBuffer(file);
        
        // Create the command to upload the file
        const command = new PutObjectCommand({
            Bucket: INPUT_BUCKET_NAME,
            Key: key,
            Body: fileContent,
            ContentType: file.type
        });
        
        // Upload the file
        await s3Client.send(command);
        
        console.log(`File uploaded successfully to ${INPUT_BUCKET_NAME}/${key}`);
        
        // Return the bucket and key for use in the processing request
        return {
            bucket: INPUT_BUCKET_NAME,
            key: key
        };
    } catch (error) {
        console.error('Error uploading file to S3:', error);
        throw error;
    }
};

/**
 * Read a file as an ArrayBuffer
 * @param {File} file - The file to read
 * @returns {Promise<ArrayBuffer>} - The file content as an ArrayBuffer
 */
const readFileAsArrayBuffer = (file) => {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        
        reader.onload = () => {
            resolve(reader.result);
        };
        
        reader.onerror = (error) => {
            reject(error);
        };
        
        reader.readAsArrayBuffer(file);
    });
}; 