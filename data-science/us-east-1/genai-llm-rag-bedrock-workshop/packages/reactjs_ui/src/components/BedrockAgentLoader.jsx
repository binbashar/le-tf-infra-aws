/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState, useEffect, forwardRef, useImperativeHandle, useCallback } from "react";
import { Grid, Select } from "@cloudscape-design/components";
import { getBedrockAgents } from "../utils/llmLib";
import { formatDates } from "../utils/helpers";

export default forwardRef(({onAgentChange }, ref) => {
    const [agents, setAgents] = useState([])
    const [selectedOption, setSelectedOption] = useState({});

    const handleOptionChange = useCallback(
        ({ detail }) => {
            setSelectedOption(detail.selectedOption);
            onAgentChange(); // Call the callback function when the selected agent changes
        },
        [onAgentChange]
    );

    useImperativeHandle(ref, () => ({
        getSelectedOption() {
            return selectedOption
        }
    }))

    const expandAgents = (agents) => {
        const agentsFull = []
        agents.forEach(ag => {
            ag.aliases.forEach(alias => { 
                agentsFull.push({ ...ag, alias: alias })
            })
        })
        return agentsFull       
    }

    useEffect(() => {
        getBedrockAgents().then((agents) => {
            const ags = expandAgents(agents)
            const agOptions = ags.map(ag => {
                console.log(ag)
                return ({
                    label: `${ag.agentName}`,
                    value: ag,
                    iconName: "gen-ai",
                    description: ag.status,
                    tags: [ `ID: ${ag.agentId}  Alias: ${ag.alias.agentAliasId}  Status: ${ag.alias.agentAliasStatus} Updated At: ${formatDates(ag.alias.updatedAt)}`]
                })
            })
            setAgents(agOptions)
            setSelectedOption(agOptions[0])
        })

    }, [])



    return (

        <Grid

            gridDefinition={[{ colspan: 12, }]}>

            <Select selectedOption={selectedOption}
                onChange={handleOptionChange}
                // onChange={({ detail }) => setSelectedOption(detail.selectedOption)}
                options={[...agents]}
                triggerVariant="option" />

        </Grid>


    )
})