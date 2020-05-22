# AWS Account Diagram generator
Set of tools to create and visualize AWS account diagrams. 

## Consideration
Inspired by https://github.com/wongcyrus/aws-account-cloud9-visualizer

## Pre requisites
- jq > 1.5

```bash
╭─delivery at Hostname on BBL-298-makefile-cost-estimation✘✘✘ using 20-05-22 - 7:41:59
╰─○ jq --version
jq-1.5-1-a5b5cbe

```

## Workflow
Account Visualization will be saved in data folder and you can use
1. Create necessary docker images: 
`make build`

2. `Preview` -> `Preview Running Application` to review the Network visualizations of **CloudMapper**.

3. Right click `navigator.html` -> `Preview` to open **aws-security-viz** and you need to load `aws.json` by copy and paste.
