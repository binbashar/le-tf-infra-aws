/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState, useRef, useCallback, useEffect } from "react"
import { Box, Spinner, Header, Container, SpaceBetween, Textarea, Button, Grid, TextContent } from "@cloudscape-design/components"
import MessageList from "../components/MessageList"
import BedrockAgentLoader from "../components/BedrockAgentLoader";
import { invokeBedrockAgent } from "../utils/llmLib"
import { buildContent } from "../utils/messageHelpers"
import ContentLayout from "@cloudscape-design/components/content-layout";
import ButtonGroup from "@cloudscape-design/components/button-group";
import Modal from "@cloudscape-design/components/modal";


// create uuid
const createId = () => {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
        var r = (Math.random() * 16) | 0,
            v = c == "x" ? r : (r & 0x3) | 0x8;
        return v.toString(16);
    });
}


export default () => {
    const [value, setValue] = useState("")
    const [loading, setLoading] = useState(false)
    const [sessionId, setSessionId] = useState(createId())
    const [messages, setMessages] = useState([])
    const [isChatModalOpen, setIsChatModalOpen] = useState(false);

    const newConversation = () => {
        console.log("newConversation")
        setLoading(true)
        setMessages([])
        setValue("")
        setSessionId(createId())
        setLoading(false)
    }

    const handleAgentChange = useCallback(() => {
        newConversation();
    }, [newConversation]);

    const handleKeyDown = (event) => {
        if (event.key === "Enter") {
            if (event.metaKey || event.ctrlKey) {
                // Send message when "Command/Ctrl" + "Enter" is pressed
                event.preventDefault();
                if (value.trim()) {
                    sendText();
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

    const handleExpandChat = (item) => {
        console.log("Button Group Item Clicked: ", item)
        if (item.detail.id === "expand") {
            console.log("Expand Chat Clicked")
            setIsChatModalOpen(!isChatModalOpen);
        }
    }

    const childRef = useRef(null);

    const sendText = async () => {
        setLoading(true)
        const currentAgent = childRef.current.getSelectedOption()
        console.log(currentAgent)
        let content = await buildContent(value, [])
        setValue("")
        setMessages(prev => [...prev, { content: content, role: "user" }])
        const response = await invokeBedrockAgent(sessionId, currentAgent.value.agentId, currentAgent.value.alias.agentAliasId, value)

        let responseContent = await buildContent(response, [])

        setMessages(prev => [...prev, { content: responseContent, role: "assistant" }])
        setLoading(false)
        setValue("")
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
                        description="Select and Agent, then ask a question."
                        actions={
                            <Button onClick={newConversation} variant="primary">Reset Conversation</Button>
                        }
                    >
                        Amazon Bedrock Agent Chatbot

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
                footer={
                    <SpaceBetween size="xs" direction="vertical">
                        <Grid className="vertically-centered" gridDefinition={[{ colspan: 11 }, { colspan: 1 }]}>
                            <Textarea
                                autoFocus
                                fitHeight
                                placeholder="Ask a question to the Agent..."
                                onChange={({ detail }) => { setValue(detail.value) }}
                                value={value}
                                disabled={loading}
                                inputMode="text"
                                onKeyDown={handleKeyDown}>
                            </Textarea>
                            <div className="button-alignment">
                                <Button
                                    iconName="send" variant="primary"
                                    loading={loading} onClick={sendText} disabled={!value.trim()}
                                />
                            </div>
                        </Grid>
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
                    </SpaceBetween>
                </div>
            </Container>
            <Modal
                className="chat-modal"
                onDismiss={() => setIsChatModalOpen(false)}
                disableContentPaddings={false}
                size="max"
                visible={isChatModalOpen}
                header="Agent Chat"
            >
                <Container
                    footer={
                        <SpaceBetween size="xs" direction="vertical">
                            <Grid className="vertically-centered" gridDefinition={[{ colspan: 11 }, { colspan: 1 }]}>
                                <Textarea
                                    fitHeight
                                    autoFocus
                                    placeholder="Ask a question to the Agent..."
                                    onChange={({ detail }) => { setValue(detail.value) }}
                                    value={value}
                                    disabled={loading}
                                    inputMode="text"
                                    onKeyDown={handleKeyDown}>
                                </Textarea>
                                <div className="button-alignment">
                                    <Button
                                        iconName="send" variant="primary"
                                        loading={loading} onClick={sendText} disabled={!value.trim()}
                                    />
                                </div>
                            </Grid>
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
                        </SpaceBetween>
                    </div>
                </Container>
            </Modal>
        </ContentLayout>

        // <Container disableContentPaddings={false}
        //     header={<Header variant="h2">Amazon Bedrock Agent Chatbot</Header>}>

        //     <SpaceBetween size="xs">
        //         <BedrockAgentLoader ref={childRef} onAgentChange={handleAgentChange} />

        //         <Box data-id="chat-window">
        //             {
        //                 messages.length ?
        //                     <Container fitHeight>
        //                         <MessageList messages={messages} />
        //                         {loading ? <Spinner /> : null}
        //                     </Container>
        //                     : null

        //             }
        //         </Box>
        //         <Textarea
        //             fitHeight
        //             placeholder="Write something to the agent..."
        //             onChange={changeHandler}
        //             value={value}
        //             disabled={loading}
        //             inputMode="text"
        //             onKeyDown={handleKeyDown}
        //         />
        //         <Button fullWidth loading={loading} onClick={sendText} variant="primary" disabled={!value.trim()}>Send</Button>
        //     </SpaceBetween>


        // </Container>
    )
}