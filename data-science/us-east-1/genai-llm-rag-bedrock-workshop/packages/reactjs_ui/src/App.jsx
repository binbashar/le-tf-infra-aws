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
import Prompt from "./views/Prompt";
import React from 'react';

const App = ({ signOut, user }) => {

  const router = createBrowserRouter([

    {
      path: "/",
      errorElement: <div>something went wrong!</div>,
      element: (
          <Struct signOut={signOut}  {...user} />
      ),
      children: [
        { path: "multimodal", element: <MultiModalLLM/> },
        { path: "prompt", element: <Prompt /> },
        { path: "bedrockagent", element: <BedrockAgent /> },

      ]
    }
  ])

  return (<RouterProvider router={router} />)
}

const Struct = ({ signOut, ...user }) =>
[
    <Menu key={1} signOut={signOut} {...user}></Menu>,
    <Layout key={2} ></Layout>,
    <Footer key={3}></Footer>
]

export default withAuthenticator(App, {
  hideSignUp: true
})