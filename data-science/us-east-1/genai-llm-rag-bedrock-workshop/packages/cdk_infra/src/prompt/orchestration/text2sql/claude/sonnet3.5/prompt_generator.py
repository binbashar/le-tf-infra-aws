# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import os
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def merge_files(template_file, table_file, schema_file, query_file, prompt_output):
    try:
        template_dir = os.path.join(os.getcwd(), 'templates')

        template_file = os.path.join(template_dir, template_file)
        table_file = os.path.join(template_dir, table_file)
        schema_file = os.path.join(template_dir, schema_file)
        query_file = os.path.join(template_dir, query_file)
        
        # Read the contents of the files
        with open(table_file, 'r', encoding='utf8') as f:
            table_contents = f.read()
        with open(schema_file, 'r', encoding='utf8') as f:
            schema_contents = f.read()
        with open(query_file, 'r', encoding='utf8') as f:
            query_contents = f.read()

        merged_content = []

        # Read orchestration template and append the contents
        with open(template_file, 'r', encoding='utf8') as template:
            for line in template:
                if '{{INSERT_TABLES}}' in line:
                    merged_content.append(table_contents)
                elif '{{INSERT_SCHEMA}}' in line:
                    merged_content.append(schema_contents)
                elif '{{INSERT_QUERY}}' in line:
                    merged_content.append(query_contents)
                else:
                    merged_content.append(line)

        # Write the merged content to the final orchestration prompt
        with open(prompt_output, 'w', encoding='utf8') as output:
            output.writelines(merged_content)
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise

merge_files(
    template_file='orchestration_template.txt',
    table_file='tables.txt',
    schema_file='schema.txt',
    query_file='query_example.txt',
    prompt_output='orchestration_prompt.txt'
    )
logger.info("The orchestartion prompt is successfully generated")
