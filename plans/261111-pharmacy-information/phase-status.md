# Pharmacy information page

- Implemented `/about` using the project's Servlet/JSP and shared header/footer.
- Added introduction, operating requirements, purchase policies, privacy and
  dated primary-source references in Vietnamese.
- Added responsive contents navigation, native disclosures and print/PDF action.
- Added entry points in shared navigation, footer and registration form.
- Fixed checklist marker mojibake by using the ASCII CSS escape `\2713`,
  explicitly declaring UTF-8 and changing the stylesheet cache version.
- Actual operator/license/contact details remain explicitly unpublished until
  supplied and verified. This is a content page, not new consent or erasure logic.
- Validation passed: isolated Ant clean/dist (91 Java sources), standard dist,
  JavaScript syntax, Tomcat HTTP/UTF-8 rendering, navigation links and blocked
  direct WEB-INF JSP access. Browser review at 1280 and 390 px found no horizontal
  overflow. Section navigation/current state, expandable legal/privacy content
  and the guest profile-to-login redirect were checked. Mobile header layout was
  adjusted to keep page content readable. Print/PDF support was implemented but
  no PDF was exported during QA.
