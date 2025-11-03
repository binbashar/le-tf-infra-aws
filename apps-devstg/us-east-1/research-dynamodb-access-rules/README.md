# Firebase to DynamoDB

## When the fire becomes a dynamo

# Abstract

You have a Firebase database in GCP and you will migrate to AWS DynamoDB.
A piece of cake, hu?

But you have custom Firebase Security Rules… DANGER.

What to do next?

# The project

You have a Firebase database partitioned by User Id.
Then you want only the user with a given User Id is the only one accessing the data in partition with that User Id.

It is not a piece of cake, but, hey, it is doable!

We will leverage Cognito, IAM, and Lambda.

## The Firebase database

### Firebase (Firestore) Schema

The schema is built on a primary hierarchy where the document ID of the root collection is the user's unique ID (userId), provided by Firebase Authentication.

#### 1. Root Collection: /users

* **Path:** /users/{userId}  
* **Purpose:** Stores the main user profile and acts as the secure anchor for all private user data. The document ID (userId) must match the authenticated user's ID (request.auth.uid) for sensitive operations.  
* **Document ID:** **{userId}** (e.g., oajs912JAs8kjsd)  
* **Data Fields:**

```json
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "created_at": <timestamp>,
  "profile_data": { ... }
}
```

#### 2\. Subcollection: /movies

* **Path:** /users/{userId}/movies/{movieId}  
* **Purpose:** Stores a list of movies saved or tracked by the individual user. This data is private to the owner.  
* **Document ID:** **{movieId}** (e.g., M1001)  
* **Data Fields:**

```json
{
  "title": "The Matrix",
  "year": 1999,
  "watched_date": <timestamp>,
  "rating": 5
}
```

#### 3\. Subcollection: /music

* **Path:** /users/{userId}/music/{songId}  
* **Purpose:** Stores a list of songs or musical entries specific to the user. This data is private to the owner.  
* **Document ID:** **{songId}** (e.g., S2005)  
* **Data Fields:**

```json
{
  "artist": "Queen",
  "title": "Bohemian Rhapsody",
  "genre": "Rock",
  "added_on": <timestamp>
}
```

#### Summary of Structure

The final schema layout is a nested model, which is common and highly effective in Firestore for enforcing user-based security rules.

```
firestore-root
└── users (Collection)
    └── {userId} (Document - The User Profile)
        ├── name: "..."
        └── email: "..."
        |
        ├── movies (Subcollection)
        │   └── {movieId} (Document - A User's Movie Entry)
        │       ├── title: "..."
        │       └── rating: "..."
        |
        └── music (Subcollection)
            └── {songId} (Document - A User's Song Entry)
                ├── artist: "..."
                └── title: "..."

```

#### Security Rules

This is the security rules definition:

```

  rules_version = '2';

  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId} {
        allow read, create: if request.auth != null;
        allow update, delete: if request.auth != null && request.auth.uid == userId;
        match /movies/{movieId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
        match /music/{songId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }

```

Let’s set a ToDo list for this project.

## Phase 0: DynamoDB Data Modeling (The "User-Centric" Table)

The DynamoDB design must ensure the user ID is the primary partitioning element for all their private data. A **Single-Table Design** is ideal here.

| Step | Action | Description | Rationale |
| :---- | :---- | :---- | :---- |
| **1.1** | **Create DynamoDB Table** | Create a single table, e.g., PrivateUserDataTable. | Stores all user profiles and their subcollection items (movies, music). |
| **1.2** | **Define Primary Keys** | Set the **Partition Key (PK)** to userId (String). Set the **Sort Key (SK)** to entityId (String). | The userId (which will be the Cognito Identity ID) ensures item-level access control via IAM. |
| **1.3** | **Populate SK Values** | Define a convention for the Sort Key to differentiate between the user profile and the subcollection data. | * **User Profile Item:** SK = PROFILE * **Movie Item:** SK = MOVIE#<movieId> * **Music Item:** SK = MUSIC#<songId> |

## Phase 1: Authentication and IAM Policy Creation (Enforcing request.auth.uid \== userId)

The **Cognito Identity ID** (${cognito-identity.amazonaws.com:sub}) is the key to enforcing the userId restriction.

| Step | Action | Description | Key IAM/Cognito Configuration |
| :---- | :---- | :---- | :---- |
| **2.1** | **Setup Cognito User Pool** | Create the User Pool for user sign-up/sign-in. | This generates the JWT for authentication. |
| **2.2** | **Setup Cognito Identity Pool** | Create the Identity Pool and link it to the User Pool. | **Crucial:** Ensure the **Authentication flow** uses the User Pool to provide temporary credentials. |
| **2.3** | **Create IAM Policy (Private)** | Create the IAM policy, PrivateDynamoDBPolicy, to govern access to PrivateUserDataTable. This policy replaces all user-specific Firebase rules. | Use the variable ${cognito-identity.amazonaws.com:sub} with dynamodb:LeadingKeys. (See Policy Snippet below). |
| **2.4** | **Configure Authenticated Role** | Attach PrivateDynamoDBPolicy to the **Authenticated Role** associated with the Identity Pool. | This role is assumed by every logged-in user to access the data. |

###

### IAM Policy Snippet (Step 2.3)

This policy handles the **Update/Delete** of the user profile and **Read/Write** to all subcollections (movies, music) by the owner.

```json

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowOwnerAccessToOwnData",
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/PrivateUserDataTable",
                "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/PrivateUserDataTable/index/*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    // This enforces the key check: 'request.auth.uid == userId'
                    "dynamodb:LeadingKeys": ["${cognito-identity.amazonaws.com:sub}"]
                }
            }
        }
    ]
}

```

The IAM condition key "dynamodb:LeadingKeys" is a crucial tool for implementing fine-grained, item-level access control in Amazon DynamoDB using AWS Identity and Access Management (IAM) policies.

In simple terms, it restricts a user's access to only those items in a DynamoDB table where the Partition Key value of the item matches a specific value provided in the access request (usually the user's ID).

---

## Phase 2: Handling Non-Owner Access (allow read, create: if request.auth \!= null;)

The remaining rules are **"Any authenticated user can read or create a user profile."** This requires handling **Creation** (any user can create their own profile) and **Reading** (any user can read *any* profile).

| Step | Action | Description | Rationale/Implementation |
| :---- | :---- | :---- | :---- |
| **3.1** | **Handling Profile Creation (allow create)** | The creation is handled automatically by the policy (Step 2.3). When a new user authenticates and receives credentials, their first PutItem (to create the PROFILE item) will use their own userId as the PK, satisfying the dynamodb:LeadingKeys condition. | **No extra policy needed.** The client-side code initiates the write with the correct PK. |
| **3.2** | **Handling Profile Read (allow read)** | Allow any authenticated user to read *any* user's profile item, but *not* their private subcollections. | This requires a **separate access path** or a highly complex IAM policy with multiple statements. **Recommendation: Use an API Gateway \+ Lambda Function.** |
| **3.3** | **Implement API Gateway Path** | Create an API Gateway endpoint (e.g., /user/{userId}) secured by a **Cognito Authorizer**. | Ensures request.auth \!= null (only authenticated users). |
| **3.4** | **Implement Lambda Function** | The Lambda function reads the requested userId from the path parameter, then performs a **GetItem** operation on the PrivateUserDataTable where PK \= userId and SK \= PROFILE. The Lambda's IAM Role will have full read permissions to the table. | This bypasses the fine-grained client-side IAM control for this specific read operation, safely enforcing the rule via a secure backend service. |

# Do it\!

## DynamoDB

We will use a **Single-Table Design** pattern that consolidates the `/users`, `/movies`, and `/music` collections into one DynamoDB table, with the user's ID as the common partitioning key.

We’ll create a table like this:

1. **Table name:** Set in **Leverage** files
2. **Partition key:**  
   * **PK**: **`userId`**  
   * **String** as the data type.  
   * *Rationale: This key will hold the user's Cognito Identity ID (`sub`) and is the pivot point for IAM access restrictions.*  
3. **Sort key:**  
   * **SK**: **`entityId`**  
   * **String** as the data type.  
   * *Rationale: This key combines the entity type (PROFILE, MOVIE, MUSIC) and the unique ID, allowing all a user's items to be efficiently queried using a single PK.*

## Cognito

We will create a user pool with an identity pool.

## The App

We will use the Python standard library boto3 to interact with both Amazon Cognito Identity Pool (cognito-identity) to get credentials, and Amazon DynamoDB (dynamodb) to perform data operations.

### Prerequisites

Before running this code, ensure you have:

1. **Basics Deployed:** Apply the **Leverage** *layer*:
    - Assets: DynamoDB Table, Cognito User Pool, Identity Pool, and the restricted IAM Role/Policy.
2. **Python dependecies installed:** `pip install requirements.txt`
3. **Other dependencies**: `jq`,

This implementation demonstrates how the complexity of fine-grained access is entirely delegated to **IAM**, allowing the client code to remain clean while being automatically and securely constrained.

### AWS Credentials first!

Note that to log in we are using the boto3 function “`client.admin_initiate_auth`”.
This is only for the sake of this demo and should not be used in a productive environment. (unless you know what you are doing)
Using it we are bypassing a few client side tasks we should do to keep the system safe, but are out of the scope of this text and they cause an overhead.  
So, for using the aforementioned function you MUST have AWS credentials set in your environment. They will be used to reach Cognito, but then the user and password set in the code will be used.  
Note that for this, one of the enabled flows for Cognito is “ALLOW\_ADMIN\_USER\_PASSWORD\_AUTH”. Do not enable it in Prod unless you really need it.

Set general AWS Credentials:
- `aws sso login`
- `export AWS\_PROFILE=dev-sso-role` (replace your role).

### How to run the test

The steps:

* `cd` into the *layer* directory
  - e.g. `cd <your-project-dir>/apps-devstg/us-east-1/research-dynamodb-access-rules`
* Apply the layer
  - `leverage tf apply`
* `cd` into the demo client directory
  - `cd demo_client`
* Run the script (read more on the script below):
  - `bash run_demo.sh`
* Drink a beer  
* Chek your results
* Play with the demo
* **Don’t forget to destroy** the testing infrastructure

#### On the script

The *shell script* in the `demo_client` directory inside the *layer* was created to be executed from the given directory.

If you want to run the shell script (and the Python script) from other directory, you must adapt the code.

### What does the App do?

- It creates two users in Cognito (using the AWS credentials you've set)
- It access Dynamo as user 1 and creates a few movies
- It access Dynamo as user 2 and creates a few movies
- It tries to access user 1 movies using user 2 credentials
