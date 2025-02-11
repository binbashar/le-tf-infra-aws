/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import React, { useState, useEffect } from "react";
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
import { colorTextStatusError } from "@cloudscape-design/design-tokens";

const EditSysPromptForm = ({ id, title, onModalDismiss, setActiveTabId }) => {

  const [roleTitle, setRoleTitle] = useState("");
  const [roleDescription, setRoleDescription] = useState("");
  const [backgroundInformation, setBackgroundInformation] = useState("");
  const [toneAndCommunicationStyle, setToneAndCommunicationStyle] =
    useState("");
  const [knowledgeAndExpertise, setKnowledgeAndExpertise] = useState("");
  const [limitationsAndBoundaries, setLimitationsAndBoundaries] = useState("");
  const [sampleDialoguesOrScenarios, setSampleDialoguesOrScenarios] =
    useState("");
  const [evaluationCriteria, setEvaluationCriteria] = useState("");
  const [feedbackAndIteration, setFeedbackAndIteration] = useState("");
  const [additionalResources, setAdditionalResources] = useState("");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  const _store = useSnapshot(store);

  const promptData = getPromptById(id);

  useEffect(() => {
    if (promptData) {
      setRoleTitle(promptData.RoleTitle || "");
      setRoleDescription(promptData.RoleDescription || "");
      setToneAndCommunicationStyle(promptData.ToneAndCommunicationStyle || "");
      setKnowledgeAndExpertise(promptData.KnowledgeAndExpertise || "");
      setLimitationsAndBoundaries(promptData.LimitationsAndBoundaries || "");
      setSampleDialoguesOrScenarios(
        promptData.SampleDialoguesOrScenarios || ""
      );
      setEvaluationCriteria(promptData.EvaluationCriteria || "");
      setFeedbackAndIteration(promptData.FeedbackAndIteration || "");
      setAdditionalResources(promptData.AdditionalResources || "");
    }
  }, [promptData]);

  const handleSave = () => {
    const formData = {
      RoleTitle: roleTitle,
      RoleDescription: roleDescription,
      BackgroundInformation: backgroundInformation,
      ToneAndCommunicationStyle: toneAndCommunicationStyle,
      KnowledgeAndExpertise: knowledgeAndExpertise,
      LimitationsAndBoundaries: limitationsAndBoundaries,
      SampleDialoguesOrScenarios: sampleDialoguesOrScenarios,
      EvaluationCriteria: evaluationCriteria,
      FeedbackAndIteration: feedbackAndIteration,
      AdditionalResources: additionalResources,
    };

    console.log(formData);
    updatePromptById(id, formData);
    console.log(_store.prompts);
    setIsModalOpen(true);
  };

  const handleDeletePrompt = () => {
    setIsDeleteModalOpen(true);
  };

  const handleCancel = () => {
    console.log("Cancel clicked");
    setIsModalOpen(false);
    onModalDismiss(); 
    setActiveTabId("first"); // Set the active tab index to 0 (first tab)
  };

  function getPromptById(id) {
    const prompt = _store.prompts.find((p) => p.id === id);

    if (prompt) {
      return prompt;
    } else {
      return `Error: No prompt found for the id "${id}".`;
    }
  }

  function updatePromptById(id, formData) {
    const prompts = _store.prompts;
    const promptIndex = prompts.findIndex((p) => p.id === id);

    if (promptIndex !== -1) {
      console.log(`updatePromptById - Found a match for id '${id}' at index ${promptIndex}`);
      const updatedPrompt = { ...prompts[promptIndex], ...formData };
      const updatedPrompts = [...prompts];
      updatedPrompts[promptIndex] = updatedPrompt;

      store.prompts = updatedPrompts;

      console.log("Stored prompts:", store.prompts);
      return updatedPrompt;
    } else {
      console.log(`No prompt found for the id "${id}".`);
      return null;
    }
  }

  function deletePromptById(id) {
    const prompts = _store.prompts;
    const promptIndex = prompts.findIndex((p) => p.id === id);

    if (promptIndex !== -1) {
      console.log(`deletePromptById - Found a match for id '${id}' at index ${promptIndex}`);
      // Remove the prompt with the given id from the prompts array
      const updatedPrompts = _store.prompts.filter((prompt) => prompt.id !== id);
      store.prompts = updatedPrompts;

      console.log("deletePromptById - Stored prompts:", store.prompts);

      setActiveTabId("first"); // Set the active tab index to 0 (first tab)
      setIsDeleteModalOpen(false);
      onModalDismiss(); // Call the onModalDismiss function to close the modal

      return true;
    } else {
      console.log(`deletePromptById - No prompt found for the id "${id}".`);
      setActiveTabId("first"); // Set the active tab index to 0 (first tab)
      setIsDeleteModalOpen(false);
      onModalDismiss(); // Call the onModalDismiss function to close the modal
      return false;
    }

  }

  const handleModalDismiss = () => {
    setActiveTabId("first"); // Set the active tab index to 0 (first tab)
    setIsModalOpen(false);
    onModalDismiss(); // Call the onModalDismiss function to close the modal
  };

  const handleDeleteModalDismiss = () => {
    setActiveTabId("first"); // Set the active tab index to 0 (first tab)
    setIsDeleteModalOpen(false);
    onModalDismiss(); // Call the onModalDismiss function to close the modal
  };

  return (
    <Box padding="m">
      <SpaceBetween direction="vertical" size="xl">
        <SpaceBetween direction="vertical" size="m">
          <FormField label="Role Title">
            <Input
              value={roleTitle}
              onChange={(e) => {
                if (e && e.detail) {
                  console.log(e.detail.value);
                  setRoleTitle(e.detail.value);
                }
              }}
              name="RoleTitle"
            />
          </FormField>

          <FormField label="Role Description">
            <Textarea
              onChange={(e) => {
                if (e && e.detail) {
                  setRoleDescription(e.detail.value);
                }
              }}
              value={roleDescription}
              placeholder="This is a placeholder"
              rows={10}
              name="RoleDescription"
            />
          </FormField>
          <Grid gridDefinition={[{ colspan: 12 }]}>
            <FormField label="Communication Tone">
              <Textarea
                onChange={(e) => {
                  if (e && e.detail) {
                    setToneAndCommunicationStyle(e.detail.value);
                  }
                }}
                value={toneAndCommunicationStyle}
                placeholder="This is a placeholder"
                rows={10}
                name="ToneAndCommunicationStyle"
              />
            </FormField>

            <FormField label="Background Information">
              <Textarea
                onChange={(e) => {
                  if (e && e.detail) {
                    setBackgroundInformation(e.detail.value);
                  }
                }}
                value={backgroundInformation}
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
                onChange={(e) => {
                  if (e && e.detail) {
                    setLimitationsAndBoundaries(e.detail.value);
                  }
                }}
                value={limitationsAndBoundaries}
                placeholder="This is a placeholder"
                rows={10}
                name="LimitationsAndBoundaries"
              />
            </FormField>

            <FormField label="SampleDialoguesOrScenarios">
              <Textarea
                onChange={(e) => {
                  if (e && e.detail) {
                    setSampleDialoguesOrScenarios(e.detail.value);
                  }
                }}
                value={sampleDialoguesOrScenarios}
                placeholder="This is a placeholder"
                rows={10}
                name="SampleDialoguesOrScenarios"
              />
            </FormField>
            <FormField label="EvaluationCriteria">
              <Textarea
                onChange={(e) => {
                  if (e && e.detail) {
                    setEvaluationCriteria(e.detail.value);
                  }
                }}
                value={evaluationCriteria}
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
          <Button variant="primary" onClick={handleDeletePrompt}>
            Delete
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
      <Modal
        onDismiss={handleDeleteModalDismiss}
        visible={isDeleteModalOpen}
        header="Are you sure you want to delete the System Prompt?"
        footer={
          <Box insetBoxLoading={false}>
            <SpaceBetween direction="horizontal" size="xs">
              <Button onClick={() => deletePromptById(id)}>Delete</Button>
              <Button onClick={handleDeleteModalDismiss}>Cancel</Button>
            </SpaceBetween>
          </Box>
        }
      >
        <TextContent>
          <p>This action cannot be undone</p>
        </TextContent>
      </Modal>
    </Box>
  );
};

export default EditSysPromptForm;
