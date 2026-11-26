# 0002 The organisation stays on the free plan; protection is per repository

Status: accepted 2026-11-26

## Context

An organisation ruleset would protect every repository, new ones included, from one definition.
GitHub offers organisation rulesets on paid plans only, and a paid plan is charged per member.

Test-Government is a voluntary organisation. People join because they use the tools.

## Decision

The organisation stays on the free plan. A price per member would turn membership into a
question of who pays, and gate collaboration on money.

Branch and tag protection is therefore a repository ruleset per repository, written in
`tofu/github` and listed in `var.repos`. Repository rulesets on public repositories are free.

## Consequences

- A repository is unprotected until it is in `var.repos` and applied. One that
  `tofu/github/repos.tf` creates gets its rulesets in the same apply.
- Every repository has to be public for its rulesets to be free.
- Features of paid plans are not designed around: no organisation ruleset, no `evaluate`
  enforcement as a dry run.
