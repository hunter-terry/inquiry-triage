# CLAUDE.md

## This project
One-liner: Self-hosted n8n workflow that drafts and validates AI replies to customer inquiries before a human ever sees them — same "never trust the raw AI reply" pattern as listit.py, built in a workflow platform instead of Python.

## How I work - read this first
- Plain language. No jargon. Explain technical words right after.
- Show me the plan before changing any files. I approve first.
- Test before handing me anything. Show proof it works.
- Preview first. Never delete or overwrite without a clear warning.
- Don't make things up. If unsure, say so.
- Done and shipped beats fancy.

## Project-specific rule
Every node that touches AI output needs a validation node immediately
after it — no raw model output ever reaches the "send" stage. See
playbooks/automation-platforms.md (in the vault root) for the platform
security rules this project follows.
