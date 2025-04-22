/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState, useRef, useCallback, useEffect } from "react"
import { Box, Spinner, Header, Container, SpaceBetween, Textarea, Button, FileUpload, Grid, TextContent, Alert, ProgressBar } from "@cloudscape-design/components"
import MessageList from "../components/MessageList"
import BedrockAgentLoader from "../components/BedrockAgentLoader";
import { invokeBedrockAgent } from "../utils/llmLib"
import { buildContent } from "../utils/messageHelpers"
import ContentLayout from "@cloudscape-design/components/content-layout";
import ButtonGroup from "@cloudscape-design/components/button-group";
import Modal from "@cloudscape-design/components/modal";
import { v4 as uuidv4 } from 'uuid';

export default () => {
    const [value, setValue] = useState("")
    const [files, setFiles] = useState([])
    const [loading, setLoading] = useState(false)
    const [sessionId, setSessionId] = useState(uuidv4())
    const [messages, setMessages] = useState([])
    const [isChatModalOpen, setIsChatModalOpen] = useState(false)
    const [uploadProgress, setUploadProgress] = useState(0)
    const [error, setError] = useState('')

    const newConversation = () => {
        console.log("newConversation")
        setLoading(true)
        setMessages([])
        setValue("")
        setFiles([])
        setSessionId(uuidv4())
        setLoading(false)
    }

    const handleAgentChange = useCallback(() => {
        newConversation();
    }, [newConversation]);

    const handleKeyDown = (event) => {
        if (event.key === "Enter") {
            if (event.metaKey || event.ctrlKey) {
                event.preventDefault();
                if (value.trim()) {
                    sendText();
                }
            } else {
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

    const handleExpandChat = (item) => {
        console.log("Button Group Item Clicked: ", item)
        if (item.detail.id === "expand") {
            console.log("Expand Chat Clicked")
            setIsChatModalOpen(!isChatModalOpen);
        }
    }

    const childRef = useRef(null);

    const handleFileUpload = async (file) => {
        try {
            setLoading(true)
            setUploadProgress(0)
            
            // Simulate upload progress
            for (let i = 0; i <= 100; i += 10) {
                await new Promise(resolve => setTimeout(resolve, 100))
                setUploadProgress(i)
            }

            const currentAgent = childRef.current.getSelectedOption()
            let content = await buildContent(`Process the document: ${file.name}`, [])
            setMessages(prev => [...prev, { content: content, role: "user" }])
            const response = await invokeBedrockAgent(sessionId, currentAgent.value.agentId, currentAgent.value.alias.agentAliasId, `Process the document: ${file.name}`)

            let responseContent = await buildContent(response, [])
            setMessages(prev => [...prev, { content: responseContent, role: "assistant" }])
            setError('')
        } catch (err) {
            setError(`Error processing document: ${err.message}`)
        } finally {
            setLoading(false)
            setUploadProgress(0)
        }
    }

    useEffect(() => {
        const scrollToSpinner = () => {
            const scrollToElement = (selector) => {
                const element = document.querySelector(selector);
                if (element) {
                    setTimeout(() => {
                        console.debug("scrolling to spinner");
                        element.scrollIntoView({ behavior: 'smooth', block: 'end' });
                    }, 300);
                }
            };

            scrollToElement('[data-id="chat-spinner"]');

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
                        setTimeout(() => {
                            const textarea = document.querySelector('textarea');
                            if (textarea) {
                                textarea.focus();
                            }

                            if (isChatModalOpen) {
                                const modalTextarea = document.querySelector('.chat-modal textarea');
                                if (modalTextarea) {
                                    modalTextarea.focus();
                                }
                            }
                        }, 500);
                    }
                }
            };

            scrollToElement('[data-id="chat-window"]');

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
                        description="Upload documents to be processed by Bedrock Data Automation"
                        actions={
                            <Button onClick={newConversation} variant="primary">Reset Conversation</Button>
                        }
                    >
                        Document Processing
                    </Header>
                    <SpaceBetween size="xs">
                        <BedrockAgentLoader ref={childRef} onAgentChange={handleAgentChange} />
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
            >
                {error && <Alert type="error">{error}</Alert>}
                <SpaceBetween size="l">
                    <FileUpload
                        onChange={({ detail }) => setFiles(detail.value)}
                        value={files}
                        i18nStrings={{
                            uploadButtonText: e => e ? "Choose files" : "Choose file",
                            dropzoneText: e => e ? "Drop files to upload" : "Drop file to upload",
                            removeFileAriaLabel: e => `Remove file ${e + 1}`,
                            limitShowFewer: "Show fewer files",
                            limitShowMore: "Show more files",
                            errorIconAriaLabel: "Error"
                        }}
                        tokenLimit={3}
                        accept=".pdf,.doc,.docx,.txt"
                        constraintText="File types supported: PDF, DOC, DOCX, TXT"
                    />
                    {files.length > 0 && (
                        <Button
                            onClick={() => handleFileUpload(files[0])}
                            disabled={loading}
                        >
                            {loading ? "Processing..." : "Upload and Process"}
                        </Button>
                    )}
                    {uploadProgress > 0 && (
                        <ProgressBar
                            value={uploadProgress}
                            label="Upload progress"
                            description={`${uploadProgress}% complete`}
                        />
                    )}
                    <MessageList messages={messages} />
                    {loading && <Spinner />}
                </SpaceBetween>
            </Container>
        </ContentLayout>
    );
}; 