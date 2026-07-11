# CONTEXT - inquiry-triage
(living "where I'm at" note - keep updating this as you go)

## One-liner
Self-hosted n8n workflow: webhook intake -> local Ollama drafts a reply
and classifies it -> validation against business rules -> passing
drafts go to a review queue, nothing auto-sends. Closes the n8n skill
gap flagged in the vault's CONTEXT.md; portfolio piece, not a paid
client project.

## Where I'm at right now (2026-07-11)
Built and tested. Workflow runs: Webhook -> Ollama Draft + Classify ->
Parse & Validate -> Write to Review Queue or Flagged. Live at
`http://localhost:5678/webhook/inquiry` when n8n + Ollama are running.

6 real test cases run (see `test-inquiries/test-results.md`), including
a prompt-injection attempt that got the model to quote a price — caught
and flagged correctly. 2 real bugs found in testing and fixed:
- Empty/malformed webhook payloads originally passed validation with
  nothing to actually respond to. Fixed with an explicit check.
- Ollama being unreachable originally returned a raw 500 instead of
  failing clean. Fixed with `onError: continueRegularOutput` plus
  explicit error handling in the validation node, matching the same
  refusal-path discipline as `listit.py`/`autosummary.py`.

## Where I'm at right now (update, 2026-07-11)
Security review after publishing: the webhook had no authentication —
anyone with the URL could fire it, which violates the vault's own
`playbooks/automation-platforms.md` rule ("webhook URLs are secrets").
Fixed by adding n8n Header Auth (credential stored in n8n's credential
store, never in the workflow file or the repo). Confirmed a request
without the token gets a clean `403`; a request with the correct token
works normally. `playbooks/automation-platforms.md` updated with the
rules that would have caught this earlier.

## Steps / plan
- ~~Get n8n running locally via npx (no Docker)~~ — done
- ~~Webhook node -> Ollama draft + classify~~ — done
- ~~Validation node (no pricing language, no PII, length cap, disclaimer
  present) -> pass/flag branch~~ — done
- ~~Passing drafts -> local review-queue file~~ — done
- ~~Test with synthetic inquiries, including one designed to fail
  validation~~ — done
- ~~Export workflow.json, screenshots, short demo, README~~ — workflow.json
  and README done; screenshot/demo left as a manual step (see README)
- ~~QA checklist, push to new GitHub repo~~ — done
- ~~Add webhook authentication~~ — done, see above

## Notes
- n8n CLI edits (`import:workflow`, `update:workflow --active`) need a
  full n8n restart to take effect — see `playbooks/fixes-log.md`.
- Ollama on this Windows machine only binds IPv4 `127.0.0.1` — use that
  instead of `localhost` in any Node/n8n HTTP call to it.
- `review-queue/` and `flagged/` fill up with real output on every run —
  gitignored, not meant to ship with the repo.
