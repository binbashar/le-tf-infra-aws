# Copyright Amazon.com and its affiliates; all rights reserved.
# SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
# Licensed under the Amazon Software License  https://aws.amazon.com/asl/

import os
import json
from typing import Annotated
from aws_lambda_powertools.event_handler import BedrockAgentResolver
from aws_lambda_powertools.event_handler.openapi.params import Query, Body

app = BedrockAgentResolver()


@app.post("/escalate", description="used to escalate to live agent")
def escalate(email: Annotated[str, Query(description="Email address to look up")]
                        ) -> Annotated[bool, Body(description="Response only True/False")]:
    # Do the confirmation of Email to account on file
    # respond with status or prompt for call back number for agent assist
    if email == "test@thebigtest.com":
        response = True
    else:
        response = False
    return response

@app.post("/password_change", description="used for changing account password")
def password_change(email: Annotated[str, Query(description="Email address to look up")],
                 phone: Annotated[str, Query(description="Phone number to verifying account information")],
                        ) -> Annotated[str, Body(description="change the account password after getting all the required information from user")]:
    
    if email and phone:
        response = "Successfully change the account password."
    else:
        response = "Failed to change the password."
    return response


def lambda_handler(event, context):
    return app.resolve(event, context)


if __name__ == "__main__":
    openApiSchema = json.loads(app.get_openapi_json_schema(openapi_version="3.0.0"))

    # Get current path
    current_path = os.path.dirname(os.path.realpath(__file__))

  
    ## Because of following warning the openAPI schema version is not changing to 3.0.0. Following code is hack to change that version programmatically.
    ## UserWarning: You are using Pydantic v2, which is incompatible with OpenAPI schema 3.0. Forcing OpenAPI 3.1
    if openApiSchema["openapi"] != "3.0.0":
        openApiSchema["openapi"] = "3.0.0"
    
    # Create new json file for the OpenAPI schema
    openapi_path = os.path.join(current_path, "openapi.json")
    with open(openapi_path, "w") as f:
        json.dump(openApiSchema, f, indent=4)