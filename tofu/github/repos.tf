# Repositories this root CREATES. A repository that already existed is not declared here: its
# settings come under tofu through `devbox run github-tofu import-repos`, which writes
# repos_imported.tf and skips everything declared in this file.
#
# A new repository: add a block here AND an entry in var.repos (the rulesets), then
# local.created_repos below, so its rulesets wait for it. Creating needs the admin token to cover
# "All repositories".

# Mobile-ID RP API mock. Created with one commit (README and licence) so the default branch exists:
# the code then arrives by pull request, like every later change, and the default-branch ruleset
# never has to be bypassed for a first push.
resource "github_repository" "mobile_id_mock" {
  name        = "mobile-id-mock"
  description = "Mock of the Mobile-ID REST API (MID DEMO replacement) for local and CI testing"
  visibility  = "public"

  auto_init        = true
  license_template = "mit" # as the organisation's other repositories

  has_issues   = true
  has_projects = false
  has_wiki     = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true

  archive_on_destroy = true # a removed block or a destroy archives; it never deletes

  lifecycle {
    ignore_changes = [has_downloads] # deprecated; omitted, it diffs true -> false on every plan
  }
}

locals {
  # name => the created resource's name. The rulesets read a repository's name through this map,
  # which is what makes them wait for the repository to exist.
  created_repos = {
    "mobile-id-mock" = github_repository.mobile_id_mock.name
  }
}
