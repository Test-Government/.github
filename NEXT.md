# Next

The next steps, in order. At most 40 lines. Delete a line when it is done.

## Needs an organisation owner

1. Apply once this has merged: 1 to change (the required check on `.github`) and 1 to add
   (`SID-mock`'s tag ruleset, without the creation rule).

## Ready

1. `SID-mock`: publish its image to GHCR as well as Docker Hub (its `docker-image.yml`; a
   workflow file, so a person pushes it). The first merge shows whether the package comes out
   public: correct `README.md`, "What stays a click", either way.
2. The takeover (`ROADMAP.md`, entry 2), one pull request per piece: the Mobile-ID mock's code
   into `mobile-id-mock`; the chart and the code change into
   `SID-mock`; the delegated OCSP responder into `ee-eid-test-pki`.
3. `templates/AGENTS.md`: the agent file each repository starts from.
4. One line in the README of `smart-id-mock` and of `SID-mock`: not an SK ID Solutions product,
   Smart-ID is their trademark.
