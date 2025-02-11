/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as React from "react";
import Cards from "@cloudscape-design/components/cards";
import Box from "@cloudscape-design/components/box";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";
import Icon from "@cloudscape-design/components/icon";
import Modal from "@cloudscape-design/components/modal";
import ColumnLayout from "@cloudscape-design/components/column-layout";
import EditSysPromptForm from "./EditSysPromptForm";
import store from "../localData/store";
import { resetLocalStorage } from "../localData/store";
import { TextContent } from "@cloudscape-design/components";

function SysPromptList(props) {
  const [modalVisible, setModalVisible] = React.useState(false);
  const [isResetModalOpen, setResetModelOpen] = React.useState(false);
  const [selectedRole, setselectedRole] = React.useState("NONE");
  const [selectedId, setselectedId] = React.useState(null);

  const prompts = props.data;
  console.log("Prompts", prompts);
  const [selectedItems, setSelectedItems] = React.useState([
    { name: "Item 2" },
  ]);

  React.useEffect(() => {
    console.log("selectedRole UPDATED", selectedRole);
  }, [selectedRole]);

  function getCardItems() {
    return prompts.map((prompt) => ({
      id: prompt.id,
      key: prompt.id,
      RoleTitle: prompt.RoleTitle || "Error loading Role",
      RoleDescription:
        prompt.RoleDescription || "Error loading Role description",
      BackgroundInformation:
        prompt.BackgroundInformation || "No background information provided.",
      ToneAndCommunicationStyle:
        prompt.ToneAndCommunicationStyle ||
        "No tone or communication style specified.",
    }));
  }

  const handleModalDismiss = () => {
    setselectedRole(null);
    setselectedId(null);
    setModalVisible(false);
  };

  const handleResetModalDismiss = () => {
    setselectedRole(null);
    setselectedId(null);
    setResetModelOpen(false);
  };

  const handleResetLocalStorage = () => {
    setselectedRole(null);
    setselectedId(null);
    setResetModelOpen(false);
    resetLocalStorage();
    window.location.reload();
  };

  return (
    <>
      <SpaceBetween size="l">
        <ColumnLayout columns={2}>
          <div></div>
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button onClick={() => setResetModelOpen(true)}>Reset System Prompts</Button>
            </SpaceBetween>
          </Box>
        </ColumnLayout>
        <Cards
          cardDefinition={{
            header: (item) => (
              <div>
                <SpaceBetween size="xs" direction="horizontal">
                  <div fontSize="heading-m">{item.RoleTitle}</div>
                  <Button
                    onClick={() => {
                      setselectedRole(item.RoleTitle);
                      setselectedId(item.id); // Add this line
                      setModalVisible(true);
                    }}
                  >
                    <Icon name="edit" />
                  </Button>
                </SpaceBetween>
              </div>
            ),
            sections: [
              {
                id: "RoleDescription",
                header: "Description",
                content: (item) => item.RoleDescription,
              },
              {
                id: "BackgroundInformation",
                header: "Background",
                content: (item) => item.BackgroundInformation,
              },
              {
                id: "ToneAndCommunicationStyle",
                header: "Tone",
                content: (item) => item.ToneAndCommunicationStyle,
              },
            ],
          }}
          cardsPerRow={[{ cards: 1 }, { minWidth: 500, cards: 2 }]}
          items={getCardItems()}
          loadingText="Loading resources"
          trackBy="id" // Use id as the trackBy property
          visibleSections={[
            "RoleDescription",
            "BackgroundInformation",
            "ToneAndCommunicationStyle",
          ]}
          empty={
            <Box margin={{ vertical: "xs" }} textAlign="center" color="inherit">
              <SpaceBetween size="m">
                <b>No Prompts</b>
                <Button>Create Prompt</Button>
              </SpaceBetween>
            </Box>
          }
        />
      </SpaceBetween>
      <Modal
        onDismiss={handleModalDismiss}
        visible={modalVisible}
        size="xl"
        header="Edit Role Prompt"
      >
        <EditSysPromptForm id={selectedId} title={selectedRole} onModalDismiss={handleModalDismiss} setActiveTabId={props.setActiveTabId}></EditSysPromptForm>
      </Modal>
      <Modal
        onDismiss={handleResetModalDismiss}
        visible={isResetModalOpen}
        header="Are you sure you want to reset the System Prompts to their default values?"
        footer={
          <Box insetBoxLoading={false}>
            <SpaceBetween direction="horizontal" size="xs">
              <Button onClick={() => handleResetLocalStorage()}>Yes</Button>
              <Button onClick={handleResetModalDismiss}>Cancel</Button>
            </SpaceBetween>
          </Box>
        }
      >
        <TextContent>
          <p>This action cannot be undone</p>
        </TextContent>
      </Modal>
    </>
  );
}
export default SysPromptList;
