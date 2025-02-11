/*
* Copyright Amazon.com and its affiliates; all rights reserved.
* SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
* Licensed under the Amazon Software License  https://aws.amazon.com/asl/
*/

import { useState } from "react";
import { Select, Grid, FormField } from "@cloudscape-design/components";
import store from "../localData/store";
import { useSnapshot } from "valtio";

const PromptPicker = ({ onSelectPrompt }) => {
  const _store = useSnapshot(store);
  const nullOption = { label: "None", value: null };
  
  const [selectedOption, setSelectedOption] = useState(nullOption);

  const options = [
    nullOption,
    ..._store.prompts.map((prompt) => ({
      label: prompt.RoleTitle,
      value: prompt.id,
    })),
  ];

  const handleChange = (event) => {
    const selectedPromptId = event.detail.selectedOption.value;
    const selectedPrompt =
      selectedPromptId !== null
        ? _store.prompts.find((prompt) => prompt.id === selectedPromptId)
        : null;
    setSelectedOption(event.detail.selectedOption);
    onSelectPrompt(selectedPrompt);
  };

  return (
    // <Grid>
      <FormField
        label="Role"
        description="Choose one of the available Role Prompts."
      >
        <Select
          selectedOption={selectedOption}
          onChange={handleChange}
          options={options}
        />
      </FormField>
    // </Grid>
  );
};

export default PromptPicker;