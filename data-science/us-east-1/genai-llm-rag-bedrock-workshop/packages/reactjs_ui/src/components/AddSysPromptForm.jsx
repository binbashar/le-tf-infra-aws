/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import React, { useState } from "react";
import {
  Box,
  Button,
  FormField,
  Input,
  Modal,
  SpaceBetween,
  TextContent,
  Textarea,
  ExpandableSection,
  Grid,
} from "@cloudscape-design/components";
import store from "../localData/store";
import { useSnapshot } from "valtio";
import { v4 as uuidv4 } from "uuid";
import { useNavigate } from 'react-router-dom';

const AddSysPromptForm = ({ setActiveTabId }) => {

  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    RoleTitle: "",
    RoleDescription: "",
    BackgroundInformation: "",
    ToneAndCommunicationStyle: "",
    KnowledgeAndExpertise: "",
    LimitationsAndBoundaries: "",
    SampleDialoguesOrScenarios: "",
    EvaluationCriteria: "",
    FeedbackAndIteration: "",
    AdditionalResources: "",
  });

  const [isModalOpen, setIsModalOpen] = useState(false);
  const _store = useSnapshot(store);

  const handleSave = () => {
    const newPrompt = {
      id: uuidv4(), // Generate a new UUID
      ...formData,
    };

    store.prompts = [..._store.prompts, newPrompt];
    console.log(_store.prompts);
    setIsModalOpen(true);
  };

  const handleCancel = () => {
    console.log("Cancel clicked");
    setActiveTabId("first"); // Set the active tab index to 0 (first tab)
  };

  const handleModalDismiss = () => {
    setIsModalOpen(false);
    setFormData({
      RoleTitle: "",
      RoleDescription: "",
      BackgroundInformation: "",
      ToneAndCommunicationStyle: "",
      KnowledgeAndExpertise: "",
      LimitationsAndBoundaries: "",
      SampleDialoguesOrScenarios: "",
      EvaluationCriteria: "",
      FeedbackAndIteration: "",
      AdditionalResources: "",
    });
    setActiveTabId("first"); // Set the active tab index to 0 (first tab)
  };

  return (
    <Box padding="m">
      <SpaceBetween direction="vertical" size="xl">
        <SpaceBetween direction="vertical" size="m">
          <FormField label="Role Title">
            <Input
              value={formData.RoleTitle}
              onChange={({ detail }) => setFormData({ ...formData, RoleTitle: detail.value })}
              name="RoleTitle"
            />
          </FormField>

          <FormField label="Role Description">
            <Textarea
              onChange={({ detail }) => setFormData({ ...formData, RoleDescription: detail.value })}
              value={formData.RoleDescription}
              placeholder="This is a placeholder"
              rows={10}
              name="RoleDescription"
            />
          </FormField>
          <Grid gridDefinition={[{ colspan: 12 }]}>
            <FormField label="Communication Tone">
              <Textarea
                onChange={({ detail }) => setFormData({ ...formData, ToneAndCommunicationStyle: detail.value })}
                value={formData.ToneAndCommunicationStyle}
                placeholder="This is a placeholder"
                rows={10}
                name="ToneAndCommunicationStyle"
              />
            </FormField>

            <FormField label="Background Information">
              <Textarea
                onChange={({ detail }) => setFormData({ ...formData, BackgroundInformation: detail.value })}
                value={formData.BackgroundInformation}
                placeholder="This is a placeholder"
                rows={10}
                name="BackgroundInformation"
              />
            </FormField>
          </Grid>
        </SpaceBetween>
        <ExpandableSection headerText="Optional">
          <Grid gridDefinition={[{ colspan: 12 }]}>
            <FormField label="LimitationsAndBoundaries">
              <Textarea
                onChange={({ detail }) => setFormData({ ...formData, LimitationsAndBoundaries: detail.value })}
                value={formData.LimitationsAndBoundaries}
                placeholder="This is a placeholder"
                rows={10}
                name="LimitationsAndBoundaries"
              />
            </FormField>

            <FormField label="SampleDialoguesOrScenarios">
              <Textarea
                onChange={({ detail }) => setFormData({ ...formData, SampleDialoguesOrScenarios: detail.value })}
                value={formData.SampleDialoguesOrScenarios}
                placeholder="This is a placeholder"
                rows={10}
                name="SampleDialoguesOrScenarios"
              />
            </FormField>
            <FormField label="EvaluationCriteria">
              <Textarea
                onChange={({ detail }) => setFormData({ ...formData, EvaluationCriteria: detail.value })}
                value={formData.EvaluationCriteria}
                placeholder="This is a placeholder"
                rows={10}
                name="EvaluationCriteria"
              />
            </FormField>
          </Grid>
        </ExpandableSection>

        <SpaceBetween direction="horizontal" size="xs">
          <Button variant="primary" onClick={handleSave}>
            Save
          </Button>
          <Button variant="primary" onClick={handleCancel}>
            Cancel
          </Button>
        </SpaceBetween>
      </SpaceBetween>

      <Modal
        onDismiss={handleModalDismiss}
        visible={isModalOpen}
        header="Data Saved"
        footer={
          <Box insetBoxLoading={false}>
            <SpaceBetween direction="horizontal" size="xs">
              <Button onClick={handleModalDismiss}>Close</Button>
            </SpaceBetween>
          </Box>
        }
      >
        <TextContent>
          <p>The data has been saved successfully.</p>
        </TextContent>
      </Modal>
    </Box>
  );
};

export default AddSysPromptForm;
