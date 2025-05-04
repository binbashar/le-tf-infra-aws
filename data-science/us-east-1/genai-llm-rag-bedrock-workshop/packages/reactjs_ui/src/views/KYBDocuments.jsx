/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import React, { useState, useEffect } from 'react';
import Box from "@cloudscape-design/components/box";
import Button from "@cloudscape-design/components/button";
import Container from "@cloudscape-design/components/container";
import Header from "@cloudscape-design/components/header";
import ContentLayout from "@cloudscape-design/components/content-layout";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Alert from "@cloudscape-design/components/alert";
import ProgressBar from "@cloudscape-design/components/progress-bar";
import Select from "@cloudscape-design/components/select";
import FileUpload from "@cloudscape-design/components/file-upload";
import Cards from "@cloudscape-design/components/cards";
import StatusIndicator from "@cloudscape-design/components/status-indicator";
import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/api';
import { post } from 'aws-amplify/api';
import { uploadFileToS3 } from '../utils/s3Utils';
import dayjs from 'dayjs';
import awsExports from '../aws-exports';
import { fetchAuthSession } from 'aws-amplify/auth';

// Import Ant Design components for the document results display
import { 
  Tag, 
  Descriptions, 
  Divider, 
  Typography, 
  Row, 
  Col, 
  message, 
  Card as AntCard,
  Steps,
  Collapse
} from 'antd';
import { FileOutlined, CheckCircleOutlined, LoadingOutlined } from '@ant-design/icons';

const { Option } = Select;
const { Title, Text } = Typography;
const { Step } = Steps;
const { Panel } = Collapse;
const API = generateClient();

// Required documents for KYB
const REQUIRED_DOCUMENTS = [
  { 
    id: 'ein_verification',
    name: 'EIN Verification Letter',
    description: 'Official document verifying the Employer Identification Number',
    status: 'pending'
  },
  { 
    id: 'income_tax_1120',
    name: 'Form 1120 Income Tax Return',
    description: 'Corporate income tax return for the most recent fiscal year',
    status: 'pending'
  },
  { 
    id: 'company_formation',
    name: 'Company Formation Document',
    description: 'Document showing company formation/incorporation details',
    status: 'pending'
  },
  { 
    id: 'actionary_composition',
    name: 'Actionary Composition',
    description: 'Document showing shareholder composition and ownership',
    status: 'pending'
  }
];

// DocumentUploader Component
const DocumentUploader = ({ onUploadComplete, onProcessingStart }) => {
  const [files, setFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [documentType, setDocumentType] = useState(null);
  const [error, setError] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [requiredDocuments, setRequiredDocuments] = useState(REQUIRED_DOCUMENTS);

  const handleUpload = async () => {
    if (files.length === 0) {
      setError('Please select a file to upload');
      return;
    }

    if (!documentType) {
      setError('Please select a document type');
      return;
    }

    const file = files[0];
    setUploading(true);
    setError(null);
    setUploadProgress(0);

    try {
      // Start progress simulation for S3 upload (0-40%)
      setUploadProgress(5);
      const s3UploadInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 40) {
            clearInterval(s3UploadInterval);
            return prev;
          }
          return prev + 5;
        });
      }, 300);
      
      // Upload file to S3
      const uploadResult = await uploadFileToS3(file);
      
      // Clear upload interval and set progress to 50%
      clearInterval(s3UploadInterval);
      setUploadProgress(50);
      
      if (!uploadResult || !uploadResult.key) {
        throw new Error('Failed to upload file to S3');
      }
      
      // Notify that processing is starting
      if (onProcessingStart) {
        onProcessingStart();
      }
      
      // Start progress simulation for API processing (50-90%)
      const apiProcessInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            clearInterval(apiProcessInterval);
            return prev;
          }
          return prev + 5;
        });
      }, 300);
      
      // Call the API to start document processing with Agent
      const apiUrl = `${awsExports.kyb_api_endpoint}/api/kyb/process`;
      
      // Get the current user's JWT token
      const { tokens } = await fetchAuthSession();
      const jwtToken = tokens.idToken.toString();
      
      // Now attempt the actual POST request
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': jwtToken,
          'Accept': 'application/json',
          'Origin': window.location.origin
        },
        body: JSON.stringify({
          s3Key: uploadResult.key,
          documentType: documentType,
          filename: file.name,
          contentType: file.type
        })
      });
    
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`API error (${response.status}): ${errorText || 'No response from server'}`);
      }
      
      // Try to parse JSON response, handle case where response might be empty
      let result;
      const responseText = await response.text();
      console.log('API Response:', responseText); // Debug log
      
      if (responseText.trim()) {
        try {
          result = JSON.parse(responseText);
          console.log('Parsed result:', result); // Debug log
        } catch (e) {
          console.error('Failed to parse API response:', e);
          throw new Error('Invalid response from server');
        }
      } else {
        // If we get here with an empty but successful response, continue
        result = { status: 'pending', message: 'Document processing initiated' };
      }
      
      // Clear processing interval and set to complete
      clearInterval(apiProcessInterval);
      setUploadProgress(100);
      
      // Update required documents status
      setRequiredDocuments(prev => 
        prev.map(doc => 
          doc.id === documentType 
            ? { ...doc, status: 'completed' } 
            : doc
        )
      );
      
      // Clear the file list
      setFiles([]);
      
      // Call the onUploadComplete callback with the documentType
      if (onUploadComplete) {
        onUploadComplete({
          ...result,
          documentType
        });
      }
      
      message.success('File uploaded and processing started');
    } catch (err) {
      console.error('Error uploading file:', err);
      
      // If we hit a CORS error, show a more helpful message
      if (err.message && err.message.includes('Failed to fetch')) {
        setError('CORS error: The API server is not accepting cross-origin requests. Please check API Gateway CORS configuration and retry in a few minutes.');
        message.error('CORS error with API Gateway');
      } else {
        setError(err.message || 'An error occurred while uploading the file');
        message.error('Failed to upload file');
      }
      
      setUploadProgress(0);
    } finally {
      setUploading(false);
    }
  };

  return (
    <Box padding="m" variant="awsui-key-label">
      <SpaceBetween size="l">
        <Header variant="h2">KYB Document Upload</Header>
        
        <Steps current={requiredDocuments.filter(doc => doc.status === 'completed').length}>
          {requiredDocuments.map(doc => (
            <Step 
              key={doc.id}
              title={doc.name}
              description={doc.description}
              icon={doc.status === 'completed' ? <CheckCircleOutlined /> : <LoadingOutlined />}
            />
          ))}
        </Steps>

        <Select
          selectedOption={documentType ? { value: documentType, label: requiredDocuments.find(dt => dt.id === documentType)?.name || documentType } : null}
          onChange={({ detail }) => setDocumentType(detail.selectedOption.value)}
          options={requiredDocuments
            .filter(doc => doc.status === 'pending')
            .map(doc => ({ value: doc.id, label: doc.name }))}
          placeholder="Select document type"
        />
        
        <FileUpload
          onChange={({ detail }) => setFiles(detail.value)}
          value={files}
          i18nStrings={{
            uploadButtonText: e => e ? "Choose files" : "Choose file",
            dropzoneText: e => e ? "Drop files to upload" : "Drop file to upload",
            removeFileAriaLabel: e => `Remove file ${e + 1}`,
            limitShowFewer: "Show fewer files",
            limitShowMore: "Show more files",
            errorIconAriaLabel: "Error"
          }}
          tokenLimit={1}
          accept=".pdf,.jpg,.jpeg,.png"
          constraintText="File types supported: PDF, JPEG, PNG (max 10MB)"
        />
        
        {uploadProgress > 0 && uploadProgress < 100 && (
          <ProgressBar
            value={uploadProgress}
            label="Upload progress"
            description={uploadProgress < 50 
              ? `Uploading to S3: ${uploadProgress}%` 
              : `Processing document: ${uploadProgress}%`}
          />
        )}
      
        {error && (
          <Alert 
            status="error"
            dismissible
            header="Upload Error"
          >
            {error}
          </Alert>
        )}
      
        <Button
          variant="primary"
          onClick={handleUpload}
          disabled={files.length === 0 || !documentType || uploading}
          loading={uploading}
        >
          {uploading ? 'Processing...' : 'Start Upload'}
        </Button>
      </SpaceBetween>
    </Box>
  );
};

// Format field value based on type
const formatFieldValue = (value) => {
  if (!value) return "-";
  
  // Format dates
  if (typeof value === 'string' && (value.includes('date') || value.includes('Date'))) {
    try {
      const dateMatch = value.match(/\d{4}-\d{2}-\d{2}/);
      if (dateMatch) {
        return dayjs(dateMatch[0]).format('MMMM D, YYYY');
      }
    } catch (e) {
      // If date parsing fails, return the original string
    }
  }
  
  // Return stringified version for objects
  if (typeof value === 'object') {
    return JSON.stringify(value);
  }
  
  return value;
};

// DocumentResult Component
const DocumentResult = ({ documentData }) => {
  console.log('Document data in result component:', documentData); // Debug log
  
  if (!documentData || !documentData.result) {
    return (
      <AntCard>
        <Title level={4}>No document data available</Title>
        <pre>{JSON.stringify(documentData, null, 2)}</pre>
      </AntCard>
    );
  }

  const documentType = documentData.documentType || 'unknown';
  const confidence = documentData.result.confidence || {};
  
  // Format confidence scores
  const confidenceItems = Object.entries(confidence).map(([key, value]) => {
    let status = 'warning';
    if (value > 0.8) status = 'success';
    else if (value < 0.6) status = 'error';
    
    return (
      <div key={key} style={{ marginBottom: '5px' }}>
        <Text>{key.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')}: </Text>
        <Tag color={status}>{(value * 100).toFixed(1)}%</Tag>
      </div>
    );
  });

  // Extract the parsed data, supporting both nested and flat structures
  const parsedData = documentData.result.parsed_data || 
                    (documentData.result.data && documentData.result.data.parsed_data) ||
                    {};
  
  console.log('Parsed data for display:', parsedData); // Debug log

  const formattedFields = Object.entries(parsedData).map(([key, value]) => ({
    label: key.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' '),
    value: formatFieldValue(value)
  }));

  return (
    <div className="document-result">
      <AntCard title={`Document Analysis Results - ${documentType.replace(/_/g, ' ').toUpperCase()}`} style={{ marginBottom: 20 }}>
        <Row gutter={16}>
          <Col span={16}>
            <Descriptions bordered column={1} size="small">
              {formattedFields.map((field, index) => (
                <Descriptions.Item key={index} label={field.label}>
                  {field.value}
                </Descriptions.Item>
              ))}
            </Descriptions>
          </Col>
          <Col span={8}>
            <AntCard title="Confidence Scores" size="small">
              {confidenceItems.length > 0 ? (
                confidenceItems
              ) : (
                <Text>No confidence scores available</Text>
              )}
            </AntCard>
          </Col>
        </Row>
      </AntCard>
      
      <Divider orientation="left">Raw Document Data</Divider>
      <AntCard size="small">
        <pre style={{ maxHeight: '300px', overflow: 'auto' }}>
          {JSON.stringify(documentData.result, null, 2)}
        </pre>
      </AntCard>
    </div>
  );
};

// Main KYBDocuments component
const KYBDocuments = () => {
  const [isUploading, setIsUploading] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingProgress, setProcessingProgress] = useState(0);
  const [documentResults, setDocumentResults] = useState([]);
  const [error, setError] = useState(null);
  const [requiredDocuments, setRequiredDocuments] = useState(REQUIRED_DOCUMENTS);

  const handleProcessingStart = () => {
    setIsProcessing(true);
    setProcessingProgress(10);
    
    // Simulate progress steps
    const interval = setInterval(() => {
      setProcessingProgress(prev => {
        if (prev >= 90) {
          clearInterval(interval);
          return prev;
        }
        return prev + 10;
      });
    }, 2000);
  };

  const handleUploadComplete = (result) => {
    setProcessingProgress(100);
    setIsProcessing(false);
    setDocumentResults(prev => [...prev, result]);
    
    // Update required documents status
    setRequiredDocuments(prev => 
      prev.map(doc => 
        doc.id === result.documentType 
          ? { ...doc, status: 'completed' } 
          : doc
      )
    );
  };

  const handleStartNew = () => {
    setDocumentResults([]);
    setProcessingProgress(0);
    setError(null);
    setRequiredDocuments(REQUIRED_DOCUMENTS);
  };

  const allDocumentsCompleted = requiredDocuments.every(doc => doc.status === 'completed');

  return (
    <ContentLayout
      header={
        <SpaceBetween size="m">
          <Header
            variant="h1"
            description="Upload and process KYB documents with intelligent extraction"
            actions={
              allDocumentsCompleted && (
                <Button onClick={handleStartNew} variant="primary">Start New KYB Process</Button>
              )
            }
          >
            KYB Document Processing
          </Header>
        </SpaceBetween>
      }
    >
      <Container>
        <SpaceBetween size="l">
          {error && (
            <Alert
              status="error"
              dismissible
              header={error.message || JSON.stringify(error)}
            >
              {error.message || JSON.stringify(error)}
            </Alert>
          )}

          {isProcessing && (
            <ProgressBar
              value={processingProgress}
              label="Processing document"
              description={processingProgress < 100 ? "Extracting information..." : "Processing complete"}
            />
          )}

          {!allDocumentsCompleted ? (
            <DocumentUploader 
              onUploadComplete={handleUploadComplete} 
              onProcessingStart={handleProcessingStart}
            />
          ) : (
            <Collapse defaultActiveKey={['0']}>
              {documentResults.map((result, index) => (
                <Panel 
                  header={`${result.documentType.replace(/_/g, ' ').toUpperCase()} Results`} 
                  key={index}
                >
                  <DocumentResult documentData={result} />
                </Panel>
              ))}
            </Collapse>
          )}
        </SpaceBetween>
      </Container>
    </ContentLayout>
  );
};

export default KYBDocuments; 