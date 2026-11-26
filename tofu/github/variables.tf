variable "org" {
  description = "GitHub organisation that owns the repositories."
  type        = string
  default     = "Test-Government"
}

variable "enforcement" {
  description = "Ruleset enforcement: active or disabled. (evaluate is Enterprise-only: accepted by the API, then inert.)"
  type        = string
  default     = "active"
  validation {
    condition     = contains(["active", "disabled"], var.enforcement)
    error_message = "enforcement must be active or disabled."
  }
}

variable "admin_bypass_mode" {
  description = "How organisation owners bypass the default-branch ruleset: pull_request (owners also go through a PR, and may merge it without the required review and checks) or always (direct pushes to the default branch work). pull_request is what keeps a seat's git token, which pushes as its owner, off the default branch."
  type        = string
  default     = "pull_request"
  validation {
    condition     = contains(["always", "pull_request"], var.admin_bypass_mode)
    error_message = "admin_bypass_mode must be always or pull_request."
  }
}

variable "repos" {
  description = "Repositories under the rulesets. required_checks: only job names that report on pull_request; a check that never reports leaves every PR unmergeable."
  type = map(object({
    required_checks           = optional(list(string), [])
    required_approvals        = optional(number, 0)   # a maintainer merges their own PR; raise it when a second reviewer exists
    require_code_owner_review = optional(bool, false) # with it on, an owner's own PR needs another owner
    protect_tags              = optional(bool, true)  # false where a workflow creates the tags: release on merge
  }))
  # Starting small: a repository not listed here has no ruleset and is untouched. Removing an
  # entry deletes that repository's rulesets. required_checks are left empty on purpose: fill
  # each in once its workflow has a job that runs on pull_request.
  # Not yet under rules: smart-id-mock, ee-eid-test-pki, TSL-test-server, mock-ocsp,
  # DD4J-test-application, nordic-testing-days-2024-talk.
  default = {
    ".github" = {} # this repository
    # Smart-ID v2 only: no new work, fixed if it breaks for someone (default branch master).
    # Tags unprotected: its workflow releases on every merge to master and creates the version
    # tag itself, with the workflow's token. A tag ruleset would refuse that step.
    SID-mock       = { protect_tags = false }
    mobile-id-mock = {} # new, created by repos.tf; where a ruleset change is tried first
  }
}
