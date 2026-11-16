# Pharmacy information and policies

The public `/about` route introduces PharmaFlow and presents pharmacy operating
requirements, purchase policies, privacy information and government references.
The page remains readable if category navigation cannot load. It performs no
business writes and requires no account. Its JSP is under `WEB-INF/views`.

## Content reviewed on 2026-11-11

- Pharmacy Law 105/2016/QH13 is read with its amendments, including
  44/2024/QH15, and implementing Decree 163/2025/ND-CP. The page describes
  PharmaFlow's existing OTC-only online purchase rule, rather than declaring
  that the legal restriction on online prescription sales has no exceptions.
- GPP reference: consolidated text 11/VBHN-BYT (2025), read with Decision
  2656/QD-BYT (2026), which repeals point dd, clause 1, Article 5 of Circular
  02/2018/TT-BYT. GPP must be maintained; a separate GPP certificate is not
  described as an invariably mandatory fourth independent license.
- Prescription reference: Circular 26/2025/TT-BYT. Special-controlled medicines:
  Decree 163/2025/ND-CP and Circular 18/2026/TT-BYT.
- Business registration: Decree 168/2025/ND-CP. Avoid the outdated assumption
  that household registration is always issued by the district authority.
- Personal data: Law 91/2025/QH15 and Decree 356/2025/ND-CP, effective
  2026-01-01. Article 42 of Decree 356 ends Decree 13/2023/ND-CP's effect.
  The supplied docid=207997 points to Decree 28/2023, not Decree 13/2023.
- Fire safety: Law 55/2024/QH15 and applicable amendments/implementing rules.
  The page does not assert a universal fire-safety license for every pharmacy.

Clickable government source records and the DAV portal are included on the
page. These references are summaries, not an exhaustive compliance assessment.

## Facts not yet supplied

Operator/legal entity, physical pharmacy address, responsible pharmacist,
certificate numbers, permitted business scope and an official customer/privacy
contact channel need to be supplied and verified. They are disclosed as missing
on the page rather than filled with fictitious details. No GPP certification or
national pharmaceutical database connection is asserted.

The privacy text reports existing password hashing and session/role checks.
It does not claim encryption of all stored data, a security certification or a
working consent/erasure request service. The shared Google Fonts request is
disclosed. No new cookies, analytics, data collection or schema were added.

## Verification

Build the NetBeans/Ant project, request `/about` on Tomcat and check UTF-8,
shared navigation, section anchors, details disclosures, print expansion and
responsive layout. Existing authentication and purchase behavior should remain
unchanged; the new links do not imply consent.
