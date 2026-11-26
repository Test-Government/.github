# Branch and tag protection for every repository in var.repos, as repository rulesets.
#
# Repository rulesets, not an organisation ruleset: organisation rulesets need a paid plan, and
# the organisation stays on the free one (docs/adr/0002). Repository rulesets on public
# repositories are free. A new repository is therefore NOT covered
# until it is added to var.repos. One that repos.tf creates gets its rulesets in the same apply.
#
# What these rules do and do not do:
#   - Nothing reaches a default branch except through a pull request, organisation owners
#     included, and nobody force-pushes or deletes one.
#   - With required_approvals = 0, the default, whoever may merge a pull request may merge their
#     own. The rules do not decide WHO may merge: that is write access, and for an agent session
#     the token it works with (README.md).
#   - Tags: only owners create, move or delete one. Where workflow_creates_tags is set, creating
#     is open to anyone with write access, and moving and deleting stay with owners.

# Default branch: changes arrive by pull request, with review; no force-push, no deletion.
resource "github_repository_ruleset" "default_branch" {
  for_each = var.repos

  name        = "default-branch"
  repository  = lookup(local.created_repos, each.key, each.key) # a created repository first
  target      = "branch"
  enforcement = var.enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"] # main or master, whichever the repository uses
      exclude = []
    }
  }

  # actor_id 1 = the organisation-admin role. The API reads it back as 0 or 1 for the same write,
  # hence the ignore_changes below.
  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = var.admin_bypass_mode
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = each.value.required_approvals
      require_code_owner_review         = each.value.require_code_owner_review
      dismiss_stale_reviews_on_push     = true # commits after an approval reopen the gate
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.required_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true # the branch must be up to date before merge
        do_not_enforce_on_create             = true

        dynamic "required_check" {
          for_each = each.value.required_checks
          content {
            context        = required_check.value
            integration_id = 15368 # GitHub Actions
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [bypass_actors[0].actor_id]
  }
}

# Tags: only organisation owners create, move or delete them. Publishing workflows trigger on tags,
# so a tag is a release decision and stays with a person. A repository that releases on merge
# (workflow_creates_tags) lets its workflow create the tag; an existing tag is still immutable.
resource "github_repository_ruleset" "tags" {
  for_each = { for k, v in var.repos : k => v if v.protect_tags }

  name        = "tags"
  repository  = lookup(local.created_repos, each.key, each.key) # a created repository first
  target      = "tag"
  enforcement = var.enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    creation         = !each.value.workflow_creates_tags
    update           = true
    deletion         = true
    non_fast_forward = true
  }

  lifecycle {
    ignore_changes = [bypass_actors[0].actor_id]
  }
}
