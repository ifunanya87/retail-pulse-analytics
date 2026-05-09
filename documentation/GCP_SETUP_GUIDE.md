# Detailed GCP Setup Guide

## Pre-requisite: 

1. **Create GCP account**: [Google Cloud Console](https://console.cloud.google.com/)
2. **Principal Permissions**

The **Principal Account** (the human user) **must** have the following administrative roles at the GCP Project level. 

| Role | Why it's needed |
| :--- | :--- |
| **Owner** | Provides full access to all resources; essential for initial infrastructure bootstrapping. |
| **Service Account Key Admin** | Allows the user to generate and download the `.json` key for local authentication. |
| **Service Usage Admin** | Required to enable BigQuery, GCS, and Resource Manager APIs automatically. |
| **Project Mover** | Necessary if the project needs to be migrated between folders or organizations. |
| **Organization Administrator** | Required for setting organization-level policies (if applicable). |


### How to Verify Your Administrative Roles
* Open the **IAM & Admin** page in the [GCP Console](https://console.cloud.google.com/iam-admin/iam).
* Locate your email address in the **Principal** column.
* Ensure the roles listed above are active for your account. If they are missing, you will encounter "Permission Denied" errors during the `make apply` phase.


3. **Create and Assign IAM Service account roles**

* Manual Start: The user creates the Service Account manually in the GCP Console.
* Elevate: The user assigns the Owner role to that Service Account temporarily.
* Execute: 
```bash
# Terraform (acting as the Service Account) now has the authority to create the BigQuery datasets, the GCS buckets, and—most importantly—assign the fine-grained roles in your main.tf.
make apply
```
* Secure: Once Terraform is done, **remove the Owner role from the Service Account**. It will continue to function using only the specific permissions Terraform just granted it.

These are the fine grained roles terraform assigns to the Service Account using **IAM Conditions** for a restricted access only to project-specific resources.

| Category | Role Name | IAM Condition (Resource Name) | Scope / Allows |
| :--- | :--- | :--- | :--- | 
| **Infra** | `Storage Admin` | `resource.name.startsWith("projects/_/buckets/iowa-liquor-")` | Provision Landing Zone (LZ) bucket infrastructure. |
| **Infra** | `BigQuery Admin` | `resource.name.startsWith("projects/[ID]/datasets/iowa_liquor_")` | Configure Bronze, Silver, and Gold datasets. |
| **Infra** | `Storage Object Admin` | `resource.name == "projects/_/buckets/[STATE_BUCKET]"` | Read/Write for Terraform remote state backend. |
| **Data Flow** | `Storage Object Admin` | `resource.name == "projects/_/buckets/iowa-liquor-bronze"` | Authorize Bruin/dlt to ingest raw retail files. |
| **Data Flow** | `BQ Data Editor` | *None (Project Level)* | **dbt**: Perform DDL/DML and manage schemas. |
| **Execution** | `BQ Job User` | *None (Project Level)* | Initiate and run BigQuery query jobs. |
| **Usage** | `Usage Consumer` | *None (Project Level)* | Project-level API and quota consumption. |
| **---** | **---** | **---** | **---** |

> **Note:** `[ID]` stands for with an actual GCP Project ID while `[STATE_BUCKET]` represents the name of the bucket used to store your Terraform `.tfstate` file.

---
