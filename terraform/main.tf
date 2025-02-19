terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 👇 Artifact Registry (For Container Storage)
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.env}-repo"
  format        = "DOCKER"
}

# 👇 Cloud Run Service
resource "google_cloud_run_service" "app" {
  name     = "${var.env}-dotnet-app"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.env}-repo/my-app:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = upper(var.env)
        }
      }
    }
  }

  autogenerate_revision_name = true
}

# 👇 IAM Access for Cloud Run (Public Access)
resource "google_cloud_run_service_iam_policy" "public_access" {
  location = var.region
  service  = google_cloud_run_service.app.name

  policy_data = <<EOF
{
  "bindings": [
    {
      "role": "roles/run.invoker",
      "members": ["allUsers"]
    }
  ]
}
EOF
}

# 👇 Workload Identity Federation (No Secrets in GitHub)
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool-${var.env}"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id   = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider-${var.env}"
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }
}

# 👇 Service Account for GitHub Actions
resource "google_service_account" "github_sa" {
  account_id   = "github-actions-${var.env}"
  display_name = "GitHub Actions SA for ${var.env}"
}

# 👇 Allow the identity pool to impersonate the service account
resource "google_service_account_iam_binding" "github_binding" {
  service_account_id = google_service_account.github_sa.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/YOUR_GITHUB_ORG/YOUR_REPO"
  ]
}

# 👇 Grant Cloud Run & Artifact Registry Permissions
resource "google_project_iam_member" "github_cloud_run" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

resource "google_project_iam_member" "github_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}
