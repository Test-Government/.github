# Security policy

This policy covers the repositories of the Test-Government organisation: mocks and test tools for
testing software that uses Estonian eID services.

## Reporting a vulnerability

Use "Report a vulnerability" on the affected repository's Security tab (GitHub private
vulnerability reporting). Include the repository and commit, what you found, steps to reproduce
it and the impact you expect. Do not open a public issue for a vulnerability.

## Scope

In scope: the code, container images and Helm charts published from these repositories.

Not a vulnerability:
- Test keys, certificates and credentials in these repositories. They are test material and
  public by design; nothing real is to be trusted on their basis.
- A mock being less strict than the service it imitates, unless its documentation says it checks
  the thing in question.
- Use of a mock in production. These tools are for test environments only.

## What to expect

Nobody is paid or assigned to look after these repositories, and no response time is promised.
A report is read when someone who works on a project that uses the tool has the time, and fixed
on the same terms, with the report credited unless you ask otherwise. A fix sent as a pull
request is the fastest way to get one.
