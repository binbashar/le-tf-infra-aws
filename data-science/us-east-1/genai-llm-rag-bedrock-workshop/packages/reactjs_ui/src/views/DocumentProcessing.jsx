/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import React, { useState } from 'react';
import { Storage } from 'aws-amplify';
import { Button, Container, Form, ProgressBar, Alert } from 'react-bootstrap';
import { v4 as uuidv4 } from 'uuid';

const DocumentProcessing = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [processingStatus, setProcessingStatus] = useState('');
  const [error, setError] = useState('');
  const [result, setResult] = useState('');

  const handleFileChange = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedFile(file);
      setError('');
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setError('Please select a file first');
      return;
    }

    try {
      setProcessingStatus('Uploading...');
      const fileId = uuidv4();
      const fileName = `${fileId}-${selectedFile.name}`;

      await Storage.put(fileName, selectedFile, {
        progressCallback: (progress) => {
          setUploadProgress((progress.loaded / progress.total) * 100);
        },
        contentType: selectedFile.type,
      });

      setProcessingStatus('Processing document...');
      // Here you would call your API endpoint to process the document
      // For now, we'll simulate processing
      setTimeout(() => {
        setProcessingStatus('Document processed successfully!');
        setResult('Document processing complete. Check the output bucket for results.');
      }, 2000);

    } catch (err) {
      setError(`Error uploading file: ${err.message}`);
      setProcessingStatus('');
    }
  };

  return (
    <Container className="mt-4">
      <h2>Document Processing</h2>
      <p className="text-muted">
        Upload documents to be processed by Bedrock Data Automation
      </p>

      {error && <Alert variant="danger">{error}</Alert>}

      <Form className="mt-4">
        <Form.Group controlId="formFile" className="mb-3">
          <Form.Label>Select Document</Form.Label>
          <Form.Control
            type="file"
            onChange={handleFileChange}
            accept=".pdf,.doc,.docx,.txt"
          />
        </Form.Group>

        <Button
          variant="primary"
          onClick={handleUpload}
          disabled={!selectedFile || processingStatus}
        >
          {processingStatus ? processingStatus : 'Upload and Process'}
        </Button>
      </Form>

      {uploadProgress > 0 && uploadProgress < 100 && (
        <ProgressBar
          now={uploadProgress}
          label={`${Math.round(uploadProgress)}%`}
          className="mt-3"
        />
      )}

      {result && (
        <Alert variant="success" className="mt-3">
          {result}
        </Alert>
      )}
    </Container>
  );
};

export default DocumentProcessing; 