/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState, useRef, useEffect } from "react"
import { Box, Spinner, Header, Container, SpaceBetween, Textarea, Button, FileUpload, Grid, TextContent } from "@cloudscape-design/components"
import MessageList from "../components/MessageList"
import FMPicker from "../components/FMPicker"
import { invokeModelStreaming } from "../utils/llmLib"
import { handleStreamingTokenResponse, buildContent } from "../utils/messageHelpers"
import PromptPicker from "../components/PromptPicker";
import store from "../localData/store";
import { useSnapshot } from "valtio";;
import ColumnLayout from "@cloudscape-design/components/column-layout";
import ContentLayout from "@cloudscape-design/components/content-layout";
import Modal from "@cloudscape-design/components/modal";
import ButtonGroup from "@cloudscape-design/components/button-group";
import AIChatIcon from "../assets/images/ai_chat_icon.svg?react";

export default () => {

    const _store = useSnapshot(store); // local store

    const [value, setValue] = useState("")
    const [files, setFiles] = useState([]);
    const [loading, setLoading] = useState(false)
    const [llmResponse, setLLMResponse] = useState("")
    const [messages, setMessages] = useState([])
    const [selectedPrompt, setSelectedPrompt] = useState(null);
    const [isChatModalOpen, setIsChatModalOpen] = useState(false);

    const handleKeyDown = (event) => {
        if (event.key === "Enter") {
            if (event.metaKey || event.ctrlKey) {
                // Send message when "Command/Ctrl" + "Enter" is pressed
                event.preventDefault();
                if (value.trim()) {
                    sendImageAndText();
                }
            } else {
                // Allow newline when "Enter" is pressed without modifiers
                return;
            }
        }
    };

    useEffect(() => {
        const textArea = document.querySelector("textarea");
        textArea.addEventListener("keydown", handleKeyDown);
        return () => {
            textArea.removeEventListener("keydown", handleKeyDown);
        };
    }, [handleKeyDown]);

    /*
    Event listener set up in the useEffect hook will only work for the Textarea component outside the Modal component.
    This is because the useEffect hook is attaching the event listener to the first Textarea element it finds in the DOM.
    This hook takes the handleKeyDown function as an argument and sets up an event listener for the keydown event on the document object. 
    The cleanup function removes the event listener when the component unmounts.
    */
    const useKeyDownListener = (handleKeyDown) => {
        useEffect(() => {
            const handleKeyDownEvent = (event) => {
                handleKeyDown(event);
            };

            if (isChatModalOpen) {
                document.addEventListener('keydown', handleKeyDownEvent);
                return () => {
                    document.removeEventListener('keydown', handleKeyDownEvent);
                };
            }
        }, [handleKeyDown, isChatModalOpen]);
    };


    useKeyDownListener(handleKeyDown);


    const newConversation = () => {
        setMessages([])
        setLLMResponse("")
        setValue("")
        setLoading(false)
        setSelectedPrompt(null); // Reset the selected prompt
    }
    const modelPickerRef = useRef(null);

    const handleLLMNewToken = ({ type, content_block, delta }) => {
        handleStreamingTokenResponse({ type, content_block, delta }, setLLMResponse, setMessages, setLoading)
    }

    const handlePromptSelection = (prompt) => {
        setSelectedPrompt(prompt);
        console.log("Selected Prompt:", prompt);
    };

    const handleExpandChat = (item) => {
        console.log("Button Group Item Clicked: ", item)
        if (item.detail.id === "expand") {
            console.log("Expand Chat Clicked")
            setIsChatModalOpen(!isChatModalOpen);
        }
    }


    const sendImageAndText = async () => {

        const currentModelId = modelPickerRef.current.getModelId()
        console.log(currentModelId)
        const systemPrompt = selectedPrompt
            ? `${selectedPrompt.RoleTitle}\n\n${selectedPrompt.RoleDescription}\n\n${selectedPrompt.BackgroundInformation}\n\n${selectedPrompt.ToneAndCommunicationStyle}\n\n${selectedPrompt.KnowledgeAndExpertise}\n\n${selectedPrompt.LimitationsAndBoundaries}\n\n${selectedPrompt.SampleDialoguesOrScenarios}\n\n${selectedPrompt.EvaluationCriteria}\n\n${selectedPrompt.FeedbackAndIteration}\n\n${selectedPrompt.AdditionalResources}`
            : null;

        setLoading(true)
        let content = await buildContent(value, files)
        console.log("CONTENT= ", content)
        setValue("")
        setFiles([])
        console.log(content)
        setMessages(prev => {
            const history = [...prev, { role: "user", content: content }]
            const body = {
                "messages": history,
                "anthropic_version": "bedrock-2023-05-31", "max_tokens": 1000
            }
            console.log("System Prompt:", systemPrompt)
            if (systemPrompt) body["system"] = systemPrompt
            console.log("Request body sent to Bedrock:", body);
            invokeModelStreaming(body, currentModelId, { callbacks: [{ handleLLMNewToken }] })

            return history
        })
    }


    /**
     * This useEffect hook is responsible for handling the scrolling behavior and focusing on the textarea
     * when new messages are added to the chat window or when the modal is opened or closed.
     *
     * It performs the following actions:
     *
     * 1. Scroll to the spinner element when new messages are being loaded.
     * 2. Scroll to the latest model response window after the new messages have been rendered.
     * 3. Set focus on the textarea element after scrolling to the latest response.
     *
     * The scrolling behavior is handled separately for the main chat window and the modal chat window.
     * The hook also handles the case when the modal is opened or closed, ensuring that the scrolling
     * and focusing behavior works correctly in both scenarios.
     */
    useEffect(() => {
        const scrollToSpinner = () => {
            const scrollToElement = (selector) => {
                const element = document.querySelector(selector);
                if (element) {
                    setTimeout(() => {
                        console.debug("scrolling to spinner");
                        element.scrollIntoView({ behavior: 'smooth', block: 'end' });
                    }, 300); // Adjust the delay as needed
                }
            };

            // Scroll to the spinner in the main chat window
            scrollToElement('[data-id="chat-spinner"]');

            // If the modal is open, scroll to the spinner inside the modal
            if (isChatModalOpen) {
                scrollToElement('.scrollable-container-modal [data-id="chat-spinner"]');
            }
        };

        console.debug("Trying to scroll to spinner");
        scrollToSpinner();

        const scrollToLatestResponse = () => {
            const scrollToElement = (selector) => {
                const element = document.querySelector(selector);
                if (element) {
                    const modelResponseWindows = element.querySelectorAll('[data-id="model-response-window"]');
                    const latestResponseWindow = modelResponseWindows[modelResponseWindows.length - 1];

                    if (latestResponseWindow) {
                        latestResponseWindow.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        // Set Focus on TextArea
                        setTimeout(() => {
                            const textarea = document.querySelector('textarea');
                            if (textarea) {
                                textarea.focus();
                            }

                            // If the modal is open, set focus on the textarea inside the modal
                            if (isChatModalOpen) {
                                const modalTextarea = document.querySelector('.chat-modal textarea');
                                if (modalTextarea) {
                                    modalTextarea.focus();
                                }
                            }
                        }, 500); // Adjust the delay as needed
                    }
                }
            };

            // Scroll to the latest response in the main chat window
            scrollToElement('[data-id="chat-window"]');

            // If the modal is open, scroll to the latest response inside the modal
            if (isChatModalOpen) {
                scrollToElement('.scrollable-container-modal [data-id="chat-window"]');
            }
        };

        scrollToLatestResponse();
    }, [messages, isChatModalOpen]);


    return (
        <ContentLayout
            defaultPadding
            headerVariant="default"
            header={
                <SpaceBetween direction="vertical" size="s">
                    <Header
                        variant="h1"
                        description="Write a Prompt. You can combine images and text in the input."
                        actions={
                            <Button onClick={newConversation} variant="primary">Reset Conversation</Button>
                        }
                    >
                        Amazon Bedrock Multimodal Chatbot

                    </Header>
                    <SpaceBetween size="xs">
                        <ColumnLayout columns={2}>
                            <FMPicker ref={modelPickerRef} multimodal={true} />
                            <PromptPicker onSelectPrompt={handlePromptSelection} />
                        </ColumnLayout>
                    </SpaceBetween>
                </SpaceBetween>
            }
        >
            <Container
                header={
                    <Header
                        variant="h2"
                        actions={
                            <SpaceBetween
                                direction="horizontal"
                                size="xs"
                            >
                                <ButtonGroup
                                    onItemClick={handleExpandChat}
                                    ariaLabel="Chat actions"
                                    items={[
                                        {
                                            type: "icon-button",
                                            id: "expand",
                                            iconName: "expand",
                                            text: "Expand",
                                        }
                                    ]}
                                    variant="icon"
                                />
                            </SpaceBetween>
                        }
                    >
                    </Header>
                }
                footer={
                    <SpaceBetween size="xs" direction="vertical">
                        <Grid className="vertically-centered" gridDefinition={[{ colspan: 11 }, { colspan: 1 }]}>
                            <Textarea
                                autoFocus
                                fitHeight
                                placeholder="Write something to the model..."
                                onChange={({ detail }) => { setValue(detail.value) }}
                                value={value}
                                disabled={loading}
                                inputMode="text"
                                onKeyDown={handleKeyDown}>
                            </Textarea>
                            <div className="button-alignment">
                                <Button
                                    iconName="send" variant="primary"
                                    loading={loading} onClick={sendImageAndText} disabled={!value.trim()}
                                />
                            </div>
                        </Grid>
                        <SpaceBetween size="s" direction="horizontal">
                            <FileUpload
                                onChange={({ detail }) => { setFiles(detail.value) }}
                                value={files}
                                i18nStrings={{ uploadButtonText: e => e ? "Choose files" : "Choose file", dropzoneText: e => e ? "Drop files to upload" : "Drop file to upload", removeFileAriaLabel: e => `Remove file ${e + 1}`, limitShowFewer: "Show fewer files", limitShowMore: "Show more files", errorIconAriaLabel: "Error" }}
                                showFileLastModified
                                showFileSize
                                showFileThumbnail
                                tokenLimit={3}
                                constraintText="Images Files" />
                        </SpaceBetween>
                    </SpaceBetween>
                }
            >
                <div className="scrollable-container">
                    <SpaceBetween size="xs">
                        <Box data-id="chat-window">
                            {
                                messages.length ?
                                    <>
                                        <MessageList messages={messages} />
                                        {loading ? <Box data-id="chat-spinner"><Spinner /></Box> : null}
                                    </>
                                    : <Box textAlign="center" fontWeight="light" variant="p">Your conversation will appear here</Box>

                            }
                        </Box>
                        {
                            llmResponse !== "" ?
                                <Container fitHeight header={<div className="header-title"><AIChatIcon className="small-icon"></AIChatIcon><TextContent><strong>Model</strong></TextContent></div>}>
                                    <div dangerouslySetInnerHTML={{ __html: llmResponse }} />
                                </Container> :
                                null
                        }
                    </SpaceBetween>
                </div>
            </Container>
            <Modal
                className="chat-modal"
                onDismiss={() => setIsChatModalOpen(false)}
                disableContentPaddings={false}
                size="max"
                visible={isChatModalOpen}
                header="Multimodal Chat"
            >
                <Container
                    footer={
                        <SpaceBetween size="xs" direction="vertical">
                            <Grid className="vertically-centered" gridDefinition={[{ colspan: 11 }, { colspan: 1 }]}>
                                <Textarea
                                    fitHeight
                                    autoFocus
                                    placeholder="Write something to the model..."
                                    onChange={({ detail }) => { setValue(detail.value) }}
                                    value={value}
                                    disabled={loading}
                                    inputMode="text"
                                    onKeyDown={handleKeyDown}>
                                </Textarea>
                                <div className="button-alignment">
                                    <Button
                                        iconName="send" variant="primary"
                                        loading={loading} onClick={sendImageAndText} disabled={!value.trim()}
                                    />
                                </div>
                            </Grid>
                            <SpaceBetween size="s" direction="horizontal">
                                <FileUpload
                                    onChange={({ detail }) => { setFiles(detail.value) }}
                                    value={files}
                                    i18nStrings={{ uploadButtonText: e => e ? "Choose files" : "Choose file", dropzoneText: e => e ? "Drop files to upload" : "Drop file to upload", removeFileAriaLabel: e => `Remove file ${e + 1}`, limitShowFewer: "Show fewer files", limitShowMore: "Show more files", errorIconAriaLabel: "Error" }}
                                    showFileLastModified
                                    showFileSize
                                    showFileThumbnail
                                    tokenLimit={3}
                                    constraintText="Images Files" />
                            </SpaceBetween>
                        </SpaceBetween>
                    }
                >
                    <div className="scrollable-container-modal">
                        <SpaceBetween size="xs">
                            <Box data-id="chat-window">
                                {
                                    messages.length ?
                                        <>
                                            <MessageList messages={messages} />
                                            {loading ? <Box data-id="chat-spinner"><Spinner /></Box> : null}
                                        </>
                                        : <Box textAlign="center" fontWeight="light" variant="p">Your conversation will appear here</Box>

                                }
                            </Box>
                            {
                                llmResponse !== "" ?
                                    <Container fitHeight header={<div className="header-title"><AIChatIcon className="small-icon"></AIChatIcon><TextContent><strong>Model</strong></TextContent></div>}>
                                        <div dangerouslySetInnerHTML={{ __html: llmResponse }} />
                                    </Container> :
                                    null
                            }
                        </SpaceBetween>
                    </div>
                </Container>
            </Modal>
        </ContentLayout>
    )
}
