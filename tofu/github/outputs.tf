output "default_branch_ruleset_ids" {
  description = "Ruleset id per repository (default branch)."
  value       = { for k, r in github_repository_ruleset.default_branch : k => r.ruleset_id }
}

output "tag_ruleset_ids" {
  description = "Ruleset id per repository (tags)."
  value       = { for k, r in github_repository_ruleset.tags : k => r.ruleset_id }
}

output "enforcement" {
  value = var.enforcement
}
