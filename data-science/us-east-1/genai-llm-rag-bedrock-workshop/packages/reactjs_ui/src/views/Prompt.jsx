/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState } from "react";
import Tabs from "@cloudscape-design/components/tabs";
import datastore from "../localData/store";
import { useSnapshot } from "valtio";
import SysPromptList from "../components/SysPromptList";
import SysPromptForm from "../components/AddSysPromptForm";
import ContentLayout from "@cloudscape-design/components/content-layout";
import { Header, SpaceBetween } from "@cloudscape-design/components"

export default () => {
  const [activeTabId, setActiveTabId] = useState("first");
  const dsState = useSnapshot(datastore);

  return (
    <ContentLayout
      defaultPadding
      headerVariant="default"
      header={
        <SpaceBetween direction="vertical" size="s">
          <Header
            variant="h1"
            description="Create or Edit System Prompts to guide a model's behavior."
          >
            System Prompts

          </Header>
        </SpaceBetween>
      }
    >
      <Tabs
        onChange={({ detail }) =>
          setActiveTabId(detail.activeTabId)
        }
        activeTabId={activeTabId}
        tabs={[
          {
            label: "Sample Role Definitions",
            id: "first",
            content: <SysPromptList data={dsState.prompts} setActiveTabId={setActiveTabId} />,
          },
          {
            label: "Add new",
            id: "second",
            content: <SysPromptForm setActiveTabId={setActiveTabId} />,
          },
        ]}
      />
    </ContentLayout>
  );
};
