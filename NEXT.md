# Next

The next steps, in order. At most 40 lines. Delete a line when it is done.

## Needs an organisation owner

1. First apply: `BOOTSTRAP.md` steps 3 to 6 (admin token, plan, apply, check the gate).
2. After the first `ci-self` run: read the check's name off the run (probably `ci / ci`) and put
   it in `required_checks` for `.github` in `tofu/github/variables.tf`. A check that never reports
   leaves every pull request unmergeable, so not before it has run.
3. After the apply: `SID-mock` still has a classic branch protection on `master`. Compare it with
   the new ruleset, then delete it (Settings, Branches) so tofu is the only source.

## Ready

1. `SID-mock`: publish its image to GHCR as well as Docker Hub (its `docker-image.yml`; a
   workflow file, so a person pushes it). The first merge shows whether the package comes out
   public: correct `README.md`, "What stays a click", either way.
2. The takeover (`ROADMAP.md`, entry 2), one pull request per piece: the Mobile-ID mock's code
   into `mobile-id-mock` once the apply has created it; the chart and the code change into
   `SID-mock`; the delegated OCSP responder into `ee-eid-test-pki`.
3. `templates/AGENTS.md`: the agent file each repository starts from.
4. One line in the README of `smart-id-mock` and of `SID-mock`: not an SK ID Solutions product,
   Smart-ID is their trademark.
