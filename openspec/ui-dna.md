# UI DNA

Clinical pharmacy software. Quiet teal on warm gray, dense but readable. Staff scan lists; customers shop. Prefer full words over clipped text.

## Design tokens

- Teal is the only brand color. Amber warns, red marks loss or error. Neutrals carry structure.
- Type is 14px body, 1.5 line height. Labels are 12px, uppercase, tracked. Numbers use tabular figures.
- Radius is 10px on controls and 14px on cards. Shadow stays soft and short.
- Spacing follows an 8px rhythm. Section breaks are roughly double that.

## Component patterns

- Primary actions are solid teal. Secondary actions are white with a hairline border. Ghost actions have no fill.
- Cards are white, one border, no heavy shadow.
- Data lists are tables with a quiet header. Cells wrap. A row that cannot stay readable in the list opens a detail view.
- Status is a short pill plus text, never color alone.
- Filters sit in one bar above the list. Empty results say what was not found.

## Interaction and motion

- Hover and focus change background or border in about 150ms. Motion does not move layout.
- Respect reduced motion. Do not animate width or height.

## Accessibility

- Text contrast stays at least 4.5:1. Focus remains visible.
- Icon-only controls have an accessible name.
- Touch targets stay at least 32px tall in admin lists, 44px for customer actions.

## Voice

- Vietnamese, direct, staff-facing on operational screens. No marketing tone in tables.
- Errors name the problem next to the field or at the top of the form.

## Layout

- Customer pages sit in a centered container. Admin pages use a sidebar plus a scrolling main column.
- Lists must not clip words. If a fact does not fit the row, link to a detail page instead of an ellipsis.

## Anti-patterns

- Do not truncate names, codes, reasons, or references with an ellipsis.
- Do not squeeze many audit columns into one row.
- Do not rely on hover to reveal the only copy of a value.
