# Visual thesis — The lit threshold

## Direction and product fit

Accessible Explanation Check-in uses **cinematic environmental art**: a quiet
classroom at blue hour, seen from a student desk, with a warm pool of light at
the doorway. The room is not surveillance theatre. It is calm, unoccupied and
human-scaled. The threshold is the product metaphor: a student moves from “I
finished it” to “here is how I thought about it,” and the teacher receives a
small, legible trace rather than a misconduct score.

The application itself behaves like a field notebook laid over this scene.
Content is primary; environmental art appears on the landing and in restrained
edge textures, then recedes during the check-in. No gradients are used. Depth
comes from flat planes, soft shadows, a one-pixel keyline and a warm focus halo.

## Palette

The palette comes from a rain-dark classroom, paper, chalk and the tungsten
light of an open doorway.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `canvas` | `#F3EEDF` oat paper | `#102522` night spruce | page ground |
| `surface` | `#FFFDF7` clean paper | `#17302C` green-black desk | working planes |
| `surface-strong` | `#E9E0CC` manila | `#21413A` chalkboard | grouped controls |
| `ink` | `#172A27` graphite green | `#F7F1E4` lamplight paper | primary text |
| `muted` | `#52635E` slate | `#B9C8C0` pale sage | supporting text |
| `accent` | `#9D421C` fired clay | `#F0A56A` doorway amber | primary action/focus |
| `accent-ink` | `#FFFFFF` white | `#172A27` spruce | accent contrast |
| `success` | `#286445` fern | `#73C69C` mint | completed/saved |
| `warning` | `#8A5A00` ochre | `#F0C66A` lantern | attention/offline |
| `danger` | `#A32F2F` red pencil | `#FF9A92` coral | errors/destructive |
| `line` | `#B7AC96` desk edge | `#45635B` chalk trace | boundaries |

All text combinations are selected for WCAG 2.2 AA contrast. State is always
expressed with words and/or a symbol as well as color. The app follows the
device’s light/dark preference and offers a persistent manual override.

## Typography

- Display: `Charter, Cambria, Georgia, serif`. The sturdy editorial face makes
  prompts feel worth listening to without resembling a test portal.
- Interface and long-form: `Inter, "Segoe UI", Arial, sans-serif`. A local
  system stack avoids font downloads and renders reliably under assistive tech.
- Scale: 16px body, 18px lead, 21px section title, 29px page title, 43px landing
  statement. Body leading is 1.55 and reading measure is capped at 68ch.
- Tabular numerals are used for dates, counts and retention periods.

## Spacing and layout

Spacing follows a 4px base: 4, 8, 12, 16, 24, 32, 48 and 72px. The student
flow is a single 720px reading column. Teacher review expands to 1120px and
uses a list/detail split only above 900px. At 390px everything becomes one
column, secondary navigation labels remain visible, and recording controls
stack. Interactive targets are at least 44px with 8px separation.

## Interaction grammar

- A check-in is a three-stop path: **Your words → Confidence → Review**. A
  textual progress line and native form elements keep the path understandable
  without sight.
- Warm amber marks the next action; chalk green marks a saved record. A dotted
  “trail” motif joins steps, echoing a line of reasoning.
- Student identity is a teacher-issued private link plus a student-entered
  display name. There are no accounts, biometrics, AI judgements or scores.
- Voice and text are peers. Voice is never required, can be replayed/removed,
  and its retention date is stated next to the recorder.
- Errors appear beside the field and in an assertive summary. Save, offline and
  verification results use a polite live region.

## Motion policy

UI transitions last 180–240ms and change only opacity or transform. New steps
move 8px from the direction of travel; save confirmation settles downward like
a note placed on a desk. Nothing loops. With `prefers-reduced-motion: reduce`,
all transforms and smooth scrolling are removed and state changes are instant.
The hero image itself is still.

## Asset plan and provenance

### Hero environment

- Subject/world: empty inclusive classroom at blue hour after rain; one desk in
  foreground with a blank index card; open doorway emitting warm light; wide,
  calm negative space; wheelchair-accessible aisle visible.
- Materials: worn oak, matte green chalkboard, rain-streaked glass, paper.
- Light/lens: cinematic naturalism, 35mm lens, eye-level seated viewpoint,
  cool window fill and warm doorway key, gentle film grain.
- Palette words: night spruce, oat paper, chalk dust, fired clay, doorway amber.
- Negative list: no people, no text, no letters/numbers, no logos, no brands,
  no screens, no surveillance cameras, no ominous mood, no fantasy objects,
  no watermark.
- Generation prompt: “Cinematic environmental editorial photograph of a calm,
  empty accessible classroom at blue hour just after rain, viewed from a seated
  student desk, blank index card and pencil in the near foreground, broad
  wheelchair-accessible aisle leading to an open doorway with warm tungsten
  light, worn oak desks, matte deep-green chalkboard with absolutely no writing,
  rain-streaked windows, cool night-spruce shadows, oat-paper and fired-clay
  accents, human and reassuring rather than institutional, quiet evidence and
  reflection, 35mm lens, eye level, realistic materials, subtle film grain,
  generous dark negative space for interface composition; no people, no text,
  no letters, no numbers, no logos, no brands, no screens, no cameras, no
  watermark.”
- Generator: Azure AI Foundry `factory-image` via the factory image script.
- License/provenance: generated specifically for this product on 2026-08-28;
  original project asset. Source PNG and prompt sidecar live in `assets/src/`.
  WebP/AVIF derivatives are build assets. The footer discloses generated art.

### Authored motifs

The doorway mark, dotted reasoning trail, confidence gauge and status symbols
are original inline SVG/CSS shapes authored in this repository. They use
`currentColor`, inherit forced-color modes and are not standalone image files.

