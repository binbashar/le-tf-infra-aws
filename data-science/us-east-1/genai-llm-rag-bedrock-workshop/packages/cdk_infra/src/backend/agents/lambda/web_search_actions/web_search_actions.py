import json
import os
import requests # Make sure this library is in a Lambda Layer
import boto3    # Import Boto3 for Secrets Manager

# Configuration
SERPAPI_BASE_URL = "https://serpapi.com/search.json"
DEFAULT_RESULTS_COUNT = 3 # Number of search results to return

# Global Boto3 clients are generally okay for Lambda as they can be reused across invocations
secrets_manager_client = boto3.client('secretsmanager')

def get_serpapi_key():
    secret_name = os.environ.get("SERPAPI_API_KEY_SECRET_NAME")
    if not secret_name:
        print("ERROR: SERPAPI_API_KEY_SECRET_NAME environment variable not set.")
        return None
    try:
        get_secret_value_response = secrets_manager_client.get_secret_value(
            SecretId=secret_name
        )
        # Assuming the secret string directly contains the API key
        return get_secret_value_response['SecretString']
    except Exception as e:
        print(f"Error retrieving secret '{secret_name}': {e}")
        return None

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    # --- 1. Extract Search Query from Agent Event ---
    search_query = " pourriez-vous rechercher sur le Web la météo à Paris? " # Default placeholder
    try:
        if 'requestBody' in event and \
           'content' in event['requestBody'] and \
           'application/json' in event['requestBody']['content'] and \
           'properties' in event['requestBody']['content']['application/json']:
            for prop_obj in event['requestBody']['content']['application/json']['properties']:
                if isinstance(prop_obj, dict) and prop_obj.get('name') == 'query':
                    search_query = prop_obj.get('value', search_query)
                    break
    except Exception as e:
        print(f"Error extracting search query: {e}. Using default: '{search_query}'")
    
    print(f"Performing web search for: {search_query}")

    # --- 2. Call SerpApi ---
    serpapi_api_key = get_serpapi_key()

    if not serpapi_api_key:
        error_message = "Search service configuration error (API key unavailable)."
        print(f"ERROR: {error_message}")
        error_payload = {"error": error_message}
        response_body = {'application/json': {'body': json.dumps(error_payload)}}
        action_response = {
            'actionGroup': event['actionGroup'],
            'apiPath': event.get('apiPath', '/searchWeb'),
            'httpMethod': event.get('httpMethod', 'POST'),
            'httpStatusCode': 500, 
            'responseBody': response_body
        }
        return {
            'messageVersion': '1.0',
            'response': action_response,
            'sessionAttributes': event.get('sessionAttributes', {}),
            'promptSessionAttributes': event.get('promptSessionAttributes', {})
        }

    params = {
        "q": search_query,
        "api_key": serpapi_api_key,
        "num": DEFAULT_RESULTS_COUNT,  # Get a few results
        "engine": "google",      # Or any other engine SerpApi supports
        "hl": "en",              # Language
        "gl": "us"               # Country
    }

    results_to_return = []
    try:
        response = requests.get(SERPAPI_BASE_URL, params=params, timeout=10) # 10 second timeout
        response.raise_for_status()  # Raises an HTTPError for bad responses (4XX or 5XX)
        search_results_data = response.json()

        # --- 3. Format Results for Bedrock Agent ---
        # SerpApi returns results in 'organic_results'. We need to map them.
        if "organic_results" in search_results_data:
            for result in search_results_data["organic_results"][:DEFAULT_RESULTS_COUNT]:
                results_to_return.append({
                    "title": result.get("title", "N/A"),
                    "snippet": result.get("snippet", "N/A"),
                    "url": result.get("link", "#") # 'link' is the key for URL in SerpApi organic results
                })
        elif "answer_box" in search_results_data and search_results_data["answer_box"]: # Handle answer box if present
             answer = search_results_data["answer_box"]
             snippet = answer.get("answer") or answer.get("snippet") or str(answer) # take first available
             results_to_return.append({
                    "title": answer.get("title", search_query),
                    "snippet": snippet,
                    "url": answer.get("link", "#")
                })

        if not results_to_return and "error" in search_results_data: # If SerpApi itself returned an error message
             results_to_return.append({
                    "title": "Search API Error",
                    "snippet": search_results_data["error"],
                    "url": "#"
                })


    except requests.exceptions.RequestException as e:
        print(f"Error calling SerpApi: {e}")
        results_to_return.append({
            "title": "Web Search Failed",
            "snippet": f"Could not retrieve search results: {str(e)}",
            "url": "#"
        })
    except Exception as e:
        print(f"An unexpected error occurred during web search: {e}")
        results_to_return.append({
            "title": "Unexpected Web Search Error",
            "snippet": "An unexpected error occurred while trying to search the web.",
            "url": "#"
        })
    
    if not results_to_return: # Ensure we always return something, even if it's just a "no results" message
        results_to_return.append({
            "title": "No Results Found",
            "snippet": f"No web search results found for '{search_query}'.",
            "url": "#"
        })

    # --- 4. Construct Agent Response ---
    response_body_payload = {"results": results_to_return}
    final_response_body = {'application/json': {'body': json.dumps(response_body_payload)}}

    action_response = {
        'actionGroup': event['actionGroup'],
        'apiPath': event.get('apiPath', '/searchWeb'), 
        'httpMethod': event.get('httpMethod', 'POST'),
        'httpStatusCode': 200,
        'responseBody': final_response_body
    }
    
    api_response = {
        'messageVersion': '1.0', 
        'response': action_response,
        'sessionAttributes': event.get('sessionAttributes', {}),
        'promptSessionAttributes': event.get('promptSessionAttributes', {})
    }
        
    return api_response 