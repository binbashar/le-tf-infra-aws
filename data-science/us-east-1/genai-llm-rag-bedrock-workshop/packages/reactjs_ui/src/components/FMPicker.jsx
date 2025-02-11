/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { getFMs } from "../utils/llmLib"
import { useState, useEffect, forwardRef, useImperativeHandle } from "react"
import {SegmentedControl, FormField, Select} from "@cloudscape-design/components"


const FMPicker = forwardRef(({ multimodal }, ref) => {
    const [selectedId, setSelectedId] = useState("Model 1")
    const [models, setModels] = useState([{ modelId: "Model 1"}, { modelId: "Model 1" }, { modelId: "Model 1"}])
    const [selectedOption, setSelectedOption] = useState(null);


    useImperativeHandle(ref, () => ({
        getModelId() {
            console.log(selectedId)
            return selectedId
        }
    }))
    useEffect(() => {
        getFMs().then(res => {
            if (multimodal == true) {
                res = res.filter(res => res.inputModalities.includes("IMAGE"))
            }
            setModels(res)
            setSelectedId(res[0].modelId)
            setSelectedOption({ label: res[0].modelName, value: res[0].modelId })
        })

    }, [])

    const getOptions = () => {
        const options = models ? models.map(model => {
            return { label: model.modelName, value: model.modelId }
        }) : []
        return options
    }

    const handleChange = (event) => {
        console.log("Handle Change", event)
        setSelectedOption(event.detail.selectedOption)
      };

    return (
        <FormField 
            label="Model"
            description="Choose one of the available models."
        >

            {/* <SegmentedControl selectedId={selectedId}
            label="Models"
                onChange={({ detail }) => setSelectedId(detail.selectedId)}
                options={getOptions()} /> */}
            <Select
                selectedOption={selectedOption}
                onChange={handleChange}
                options={getOptions()}
            />

        </FormField>
    )
})

export default FMPicker