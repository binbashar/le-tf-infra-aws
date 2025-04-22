/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import React from 'react'
import ReactDOM from 'react-dom/client'
import { Amplify } from 'aws-amplify'
import App from './App.jsx'
import './styles/index.css'
import "@cloudscape-design/global-styles/index.css"
import "@aws-amplify/ui-react/styles.css"
import { applyMode, Mode } from '@cloudscape-design/global-styles';
import awsconfig from './aws-exports'

// Get the theme mode from session storage
const storedThemeMode = sessionStorage.getItem('themeMode');
console.log("Stored theme mode:", storedThemeMode);

// Check if the stored theme mode is a valid value for the Mode enum
const isValidMode = Object.values(Mode).includes(storedThemeMode);
console.log("Is valid mode:", isValidMode);

// Apply the stored theme mode or use the default (Light)
const initialThemeMode = isValidMode ? storedThemeMode : Mode.Light;
console.log("Initial theme mode:", initialThemeMode);
applyMode(initialThemeMode);

// Store the current theme mode in session storage
sessionStorage.setItem('themeMode', initialThemeMode);
console.log("Stored theme mode after update:", sessionStorage.getItem('themeMode'));

// Configure Amplify with Cognito
Amplify.configure({
  ...awsconfig,
  ssr: true,
  Auth: {
    region: awsconfig.aws_project_region,
    userPoolId: awsconfig.aws_user_pools_id,
    userPoolWebClientId: awsconfig.aws_user_pools_web_client_id,
    authenticationFlowType: 'USER_SRP_AUTH'
  }
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <App />
)
