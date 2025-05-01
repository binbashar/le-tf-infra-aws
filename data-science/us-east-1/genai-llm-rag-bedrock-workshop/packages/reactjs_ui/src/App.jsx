/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { createBrowserRouter, RouterProvider } from "react-router-dom"
import { withAuthenticator } from '@aws-amplify/ui-react'
import './styles/App.css'
import Menu from "./components/Menu"
import Layout from './components/Layout'
import Footer from './components/Footer'
import BedrockAgent from "./views/BedrockAgent"
import MultiModalLLM from "./views/MultiModalLLM"
import Prompt from "./views/Prompt"
import KYBDocuments from "./views/KYBDocuments"
import React from 'react';

const App = ({ signOut, user }) => {
  const router = createBrowserRouter([
    {
      path: "/",
      element: (
        <div className="app-container">
          <Menu signOut={signOut} {...user} />
          <Layout />
          <Footer />
        </div>
      ),
      children: [
        { path: "multimodal", element: <MultiModalLLM /> },
        { path: "prompt", element: <Prompt /> },
        { path: "bedrockagent", element: <BedrockAgent /> },
        { path: "kybdocuments", element: <KYBDocuments /> },
      ]
    }
  ]);

  return <RouterProvider router={router} />;
};

export default withAuthenticator(App, {
  hideSignUp: true
});