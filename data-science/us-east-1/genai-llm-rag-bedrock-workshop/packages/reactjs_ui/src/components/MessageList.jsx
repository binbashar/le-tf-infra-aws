/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import * as React from "react"
import { Box, CopyToClipboard, Grid, Container, SpaceBetween, TextContent, Icon, Header, ButtonGroup } from "@cloudscape-design/components"
import { marked } from "marked";
import hljs from "highlight.js";
import AIChatIcon from "../assets/images/ai_chat_icon.svg?react";
import UserChatIcon from "../assets/images/user_chat_icon.svg?react";

let config = { startOnLoad: true, flowchart: { useMaxWidth: false, htmlLabels: true } };


const renderer = new marked.Renderer();

renderer.code = function (code, language) {
    if (code.match(/^sequenceDiagram/) || code.match(/^graph/)) {
        return '<pre class="mermaid">' + code + '</pre>';
    } else {
        if (language != undefined && language != '') {
            // console.log("CODE LANGUAGE: ", language)
            const highlighted = hljs.highlight(code, { language }).value;
            return `<pre><code class="hljs ${language}">${highlighted}</code></pre>`;
        }
        else {
            return '<pre><code class="hljs language-plaintext">' + code + '</code></pre>';
        }
    }
};


const UserMessage = ({ msg }) => {
    const contentJSX = (
        <Grid disableGutters gridDefinition={[{ colspan: 12 }]}>
            <Container
                // className={storedThemeMode  == 'dark' ? "user-chat-message-dark" : "user-chat-message"}
                data-sender="user"
                header={
                    <Header
                        variant="h2"
                        actions={
                            <SpaceBetween direction="horizontal" size="xs">
                                {/* <CopyToClipboard key={1} variant="icon" copyButtonAriaLabel="Copy Text" copySuccessText="copied!" copyErrorText="failed to copy" textToCopy={item.text} />, */}
                            </SpaceBetween>
                        }
                    >
                        <div className="header-title">
                            {/* <Icon size="small" name="user-profile-active"></Icon> */}
                            <UserChatIcon className="small-icon"></UserChatIcon>
                            <TextContent>
                                <strong>You</strong>
                            </TextContent>
                        </div>
                    </Header>
                }
            >
                <TextContent style={{ whiteSpace: "pre-wrap" }}>
                    {msg.content.map((item, i) => {
                        let html_msg = null;
                        let src = null;

                        if (item.type === "text") {
                            html_msg = marked.parse(item.text, { renderer: renderer });
                        }
                        if (item.type === "image") {
                            src = `data:${item.source.media_type};${item.source.type},${item.source.data}`;
                        }

                        return (
                            <div key={i}>
                                {html_msg && <div dangerouslySetInnerHTML={{ __html: html_msg }}></div>}
                                {src && (
                                    <div className="user-image-container">
                                        <img className="full-width-image" src={src} />
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </TextContent>
            </Container>
        </Grid>
    );

    return contentJSX;
};


const BotMessage = ({ msg }) => {

    const contentJSX = msg.content.map((item, i) => {

        if (item.type === "text") {
            const html_msg = marked.parse(item.text, { renderer: renderer })

            // console.log("BOT TEXT MSG: ", item.text)
            // console.log("BOT HTML MSG: ", html_msg)

            return [
                <Box data-id={"model-response-window"}>
                    <Container
                        // className={storedThemeMode == 'dark' ? "model-chat-message-dark" : "model-chat-message"}
                        variant="stacked"
                        data-sender="bot"
                        header=
                        {
                            <Header
                                variant="h2"
                                actions={
                                    <SpaceBetween
                                        key={"sb" + i}
                                        direction="horizontal"
                                        size="xs"
                                    >
                                        <CopyToClipboard variant="icon" copyButtonAriaLabel="Copy Text" copySuccessText="copied!" copyErrorText="failed to copy" textToCopy={item.text} />
                                    </SpaceBetween>
                                }
                            >
                                <div className="header-title"><AIChatIcon className="small-icon"></AIChatIcon><TextContent><strong>Model</strong></TextContent></div>
                            </Header>

                        }
                    >
                        <div className="bot-message" dangerouslySetInnerHTML={{ __html: html_msg }} ></div>
                    </Container>
                </Box>]
        }
        if (item.type === "image") {
            let src = `data:${item.source.media_type};${item.source.type},${item.source.data}`
            return <img width={700} src={src} />
        }

    })
    return (<Grid
        disableGutters
        gridDefinition={[{ colspan: 12, }]}>

        {contentJSX}
    </Grid>)
}


const SystemMessage = ({ msg }) => {
    const html_msg = msg.text.replace(/\n/g, "<br />")
    return (
        <Grid
            disableGutters
            gridDefinition={[{ colspan: 11, }, { colspan: 5 }]}>
            <Container data-sender="system" >
                <div dangerouslySetInnerHTML={{ __html: html_msg }} />
            </Container>
            <Box float="right" padding={{ right: "l" }} ><em>{msg.name}</em></Box>
        </Grid>
    )
}

const MessageList = ({ messages }) => {
    // console.log("MESSAGES: ", messages)
    return (
        <SpaceBetween key={"messages-container"} size="xs">
            {messages.map((msg, i) => {
                const role = msg.role;
                if (role === "user") return <UserMessage key={`user-${i}`} msg={msg} />;
                if (role === "assistant") return <BotMessage key={`bot-${i}`} msg={msg}/>;
                if (role === "system") return <SystemMessage key={`system-${i}`} msg={msg} />;
                return null;
            })}
        </SpaceBetween>
    );
};

export default MessageList