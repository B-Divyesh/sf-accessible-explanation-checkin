# Landing copy audit — 2026-08-29

| Text | Words | Result |
| --- | ---: | --- |
| Student explanation check-ins for teachers | 5 | plain heading |
| Collect student reasoning | 3 | job-first h1 |
| For teachers who need a low-stakes check-in, students explain one choice by text or voice. | 15 | plain audience and outcome |
| Try it with sample data | 5 | result-naming primary action |
| Open a populated teacher review; nothing is saved. | 8 | action outcome |
| Read the three steps | 4 | result-naming secondary action |
| No accounts | 2 | fact |
| Voice deletes on your schedule | 5 | tested fact |
| Free check-ins accept 35 responses | 5 | tested fact |
| What a teacher receives | 4 | informational label |
| How the check-in works | 4 | task heading |
| Review a student’s explanation, confidence, and optional voice note. | 9 | plain task |
| Use them to plan a follow-up conversation. | 7 | plain outcome |
| Create one check-in | 3 | task heading |
| Ask one question about a choice or step. | 8 | plain instruction |
| Students explain their reasoning | 4 | task heading |
| Students can complete the form using only a keyboard. | 9 | tested accessibility wording |
| Review each explanation | 3 | task heading |
| Save tags and notes for your next conversation. | 8 | tested action |
| What this tool does not do | 6 | informational heading |
| It does not grade, detect AI use, proctor, or verify identity. | 11 | plain limit |
| Privacy limits | 2 | informational heading |
| Voice deletes on the selected schedule. | 6 | tested retention fact |
| Keep private review links secure. | 5 | plain instruction |
| Original generated classroom art · Param Factory, 2026 | 8 | provenance |
| Built by Param Factory · version 1.0.0 | 7 | builder and release identity |

No landing sentence exceeds 22 words or contains a banned word. Every factual promise maps to `.factory/claims.json`.

## Round 5 revised copy

| Text | Words | Result |
| --- | ---: | --- |
| Creating a check-in stores these form fields, private-link tokens, limits, and timestamps. | 12 | precise stored-data claim |
| Recent review links are saved only in this browser. | 9 | tested browser-local claim |
| The service stores check-in and response fields, private-link tokens, response and retention limits, and timestamps. | 15 | precise stored-data claim |
| Optional voice adds an audio file, file type, and deletion time. | 11 | precise stored-data claim |
| Text does not follow the voice deletion schedule. | 8 | tested retention boundary |
| Ask your teacher to coordinate access, correction, or deletion. | 9 | contact instruction, not an outcome promise |
| Refunds are requested there; a refunded license becomes inactive here. | 9 | recorded refund-state contract |
| The deployment gate checks private links, submission, and teacher review. | 10 | concise operator instruction |
| It repeats those checks after replacing the production revision. | 9 | concise operator instruction |

The inaccurate storage-only sentence and unproved infrastructure, completed-deletion, moderation, and legal-change promises were removed. No revised sentence exceeds 22 words or contains a banned word.

## Terminology

| Concept | Term used |
| --- | --- |
| Teacher-created activity | check-in |
| Student response | explanation |
| Teacher workspace | review |
| Student record | receipt |

## Round 6 revised copy

| Text | Words | Result |
| --- | ---: | --- |
| Start for real discards sample edits before creating a private check-in. | 11 | plain demo lifecycle instruction |
| Nothing recorded. Maximum 2 minutes / 4 MB. | 8 | exact tested recording limit |
| Your teacher can delete it sooner. | 6 | exact tested deletion control |
| Teachers can delete voice sooner. | 5 | exact tested deletion control |
| The deployment test checks the storage mount, one-replica setting, and repeated private-link reads. | 13 | concrete operator instruction |
| Collect student reasoning in private text or voice check-ins for teachers. | 11 | verb-first catalog description |

No round 6 sentence exceeds 22 words or contains a banned word. The three
behavior statements map to `demo-exit-disposal`, `voice-recording-limits`, and
`teacher-voice-deletion` in `.factory/claims.json`.
