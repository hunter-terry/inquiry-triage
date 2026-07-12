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

## Where I'm at right now (update, 2026-07-11)
Model portability fix: the workflow hardcoded `llama3.1:8b` because
that's what fits this machine's RAM specifically — not a safe
assumption for a portfolio piece meant to be cloned onto other
machines. Added a RAM-based model selection table to the README. Also
found and fixed a real bug while testing this: a "model not pulled"
error from Ollama was being caught by the same generic handler as
"Ollama unreachable," so it showed a misleading message. Now gives a
distinct, accurate message. Verified both ways with a real (temporarily
broken) test run before reverting to the working model.

## Where I'm at right now (update, 2026-07-12)
Built `docs/walkthrough.html` — a plain-language, client-facing demo
page (two live runs captured, including the prompt-injection case that
got caught and blocked) for portfolio/Upwork use, published as a
shareable Claude Artifact — see the vault's `job-search/upwork-profile.md`
for the live link. While capturing it, found this
n8n instance (on the rebuilt Windows machine) has **no credentials at
all** in its database — the Header Auth credential documented above on
2026-07-11 never made it into this environment (likely lost in the
post-MacBook rebuild, not a regression from anything done today).
`workflow.json`'s `headerAuth` config is untouched and correct; the
webhook currently fails with "No authentication data defined on node!"
until a real credential is created in this n8n instance and attached to
the Webhook node's Authentication field. Not urgent (no client relying
on this instance), but do this before treating this environment's
n8n as ready to demo live to anyone.

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
