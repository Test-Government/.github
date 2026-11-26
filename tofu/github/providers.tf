# Auth = the GITHUB_TOKEN environment variable: a fine-grained PAT, resource owner = the org,
# repository permission Administration: read and write (+ Metadata). scripts/github-tf.sh sets it.
# No agent session ever holds this token; the root is applied by an org owner from their own machine.
provider "github" {
  owner = var.org
}
