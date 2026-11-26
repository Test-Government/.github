# Test-Government

Estonia runs on electronic identity: people log in and sign with an ID-card, Mobile-ID or Smart-ID,
and a signature counts because the issuing certificate authority is on the national trusted list.
Software built on that depends on services nobody controls in a test: the certificate authorities,
their OCSP responders, the Smart-ID and Mobile-ID back ends, the trusted list.

Test-Government is that state infrastructure rebuilt as test doubles you run yourself, in Docker,
locally or in CI. Every answer is under your control, including the ones the real services give
rarely or never on demand: a revoked certificate, a withdrawn trust service, an OCSP outage, a user
who refuses to sign.

For test environments only: the keys and certificates here are test material and public by design.
A community project, not affiliated with the Estonian state or with the providers of the real
services.

Nobody is assigned to look after these repositories. They were written by people who needed them
for a project, and something gets fixed when it breaks for someone who still uses it and has the
time. Expect that, and send a pull request when you can.

| Repository | What you get |
|---|---|
| [ee-eid-test-pki](https://github.com/Test-Government/ee-eid-test-pki) | The certificate authorities behind Estonian eID, reproduced for testing: issue, fetch and revoke test persons' authentication and signing certificates for ID-card and Smart-ID, with CRL and OCSP that can be made to fail |
| [smart-id-mock](https://github.com/Test-Government/smart-id-mock) | Stands in for the Smart-ID DEMO service (RP API v3): authentication, signing and certificate choice, with the outcome decided by which test account you use |
| [SID-mock](https://github.com/Test-Government/SID-mock) | The same for Smart-ID RP API v2, the older version. No new work is planned |
| [TSL-test-server](https://github.com/Test-Government/TSL-test-server) | Creates, signs and serves trusted lists (LOTL and national lists) from templates, to test how signature validation reacts to a changed, withdrawn or wrongly signed trust service |
| [mock-ocsp](https://github.com/Test-Government/mock-ocsp) | A small stand-alone OCSP responder that answers "good" for the test certificates you give it. Legacy: ee-eid-test-pki has its own OCSP, use that for new work |
| [DD4J-test-application](https://github.com/Test-Government/DD4J-test-application) | DigiDoc4j, the Estonian digital signature library, behind an HTTP API: validate signed containers against a test trust setup without writing Java |

Contributing: [CONTRIBUTING.md](https://github.com/Test-Government/.github/blob/main/CONTRIBUTING.md). Security: [SECURITY.md](https://github.com/Test-Government/.github/blob/main/SECURITY.md).
