/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { Outlet, useNavigate } from "react-router-dom";
import { useState, useEffect } from "react";
import { AppLayout, SideNavigation } from "@cloudscape-design/components";
export default () => {
  const [activeHref, setActiveHref] = useState("/");
  useEffect(() => {
    setActiveHref("/");
  }, []);

  let navigate = useNavigate();

  return (
    <AppLayout
      headerSelector="#h"
      toolsHide={true}
      disableContentPaddings={false}
      navigationHide={false}
      navigation={
        <SideNavigation
          activeHref={activeHref}
          // header={{ href: "/", text: "Demos" }}
          items={[
            {
              type: "section",
              text: "Amazon Bedrock LLMs",
              items: [
                /*                                     { type: "link", href: "/llm", text: "Chat Q&A" },
                            { type: "link", href: "/chat", text: "Chat with Memory" }, */
                {
                  type: "link",
                  href: "/multimodal",
                  text: "Multimodal Chatbot",
                },
                {
                  type: "link",
                  href: "/prompt",
                  text: "System Prompts",
                },
              ],
            },
            { type: "divider" },
            {
              type: "section", text: "Amazon Bedrock Agents", items: [
                { type: 'link', text: `Agent Chatbot`, href: `/bedrockagent` },
              ]
            },
            {type: "divider"},
            {
              type: "link",
              text: "Amazon Bedrock",
              href: "https://aws.amazon.com/bedrock/",
              external: true,
              externalIconAriaLabel: "Opens in a new tab"
            }
          ]}
          onFollow={(event) => {
            if (!event.detail.external) {
              event.preventDefault();
              console.log(event.detail.href);
              setActiveHref(event.detail.href);
              navigate(event.detail.href);
            }
          }}
        />
      }
      content={<Outlet />}
    />
  );
};
