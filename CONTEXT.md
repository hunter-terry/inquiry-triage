# CONTEXT - inquiry-triage
(living "where I'm at" note - keep updating this as you go)

## One-liner
Self-hosted n8n workflow: a real contact-form webhook intake -> local
Ollama drafts a reply and classifies it -> validation against business
rules -> passing drafts go to Airtable as "Needs Review", failing ones
as "Flagged" (phone-visible, nothing auto-sends). Closes the n8n skill
gap flagged in the vault's CONTEXT.md; portfolio piece, not a paid
client project.

## Where I'm at right now (update, 2026-07-15, retry fix republished)
Republished the retry fix from the checklist audit below (`retryOnFail`
on the Ollama node) - n8n was down when that fix landed, so it had never
actually gone live until now. Doing so hit the same Airtable Base/Table
reset the 2026-07-15 audit below already knew about, but this time it
happened on a code-only change with zero Airtable-node edits, which
exposed that "expect to redo this by hand" was a real recurring cost,
not a one-off. Fixed properly instead: switched `Airtable Create -
Needs Review` / `- Flagged` to reference `$env.AIRTABLE_BASE_ID` /
`$env.AIRTABLE_INQUIRIES_TABLE_ID` as expressions rather than
live-picked values, and added the missing `credentials` link both nodes
had never actually had in the committed file (a separate bug from the
Base/Table one, same root cause - see the vault's `fixes-log.md` and
`playbooks/automation-platforms.md` for full detail, not duplicated
here). Verified end-to-end after the fix: execution 915,
`execution_entity.status='success'`, real Airtable record written
(`recwbZfjRXz8X7k6y`). Both `workflow.json` and vault-root docs updated
and consistent; not yet committed in this project's own repo (only the
vault-root docs were touched as new files/edits this session need a
separate commit decision).

## Where I'm at right now (update, 2026-07-15, checklist audit)
Ran the vault's new `standards/security-standard.md` checklist against this
workflow (first real test of the vault's new `verify-against-standard`
skill). Confirmed `credentials.json` and `demo-form.html` were never
actually tracked in git (checked `git ls-files`, not just `.gitignore`).
Found one real gap the earlier manual audit missed: the "Ollama Draft +
Classify" node had a timeout but no retry — a transient failure failed
clean instead of retrying. Fixed in `workflow.json`: added
`retryOnFail: true, maxTries: 3, waitBetweenTries: 2000` (n8n's retry is
fixed-interval, not true exponential backoff — a platform limitation, not
a choice). **Not yet republished** — n8n wasn't running when this fix was
made; needs `npx n8n import:workflow --input=workflow.json` +
`publish:workflow` + restart next time n8n is up, then a real test call
to confirm nothing broke, per this vault's documented draft/publish
quirk. HTTP-not-HTTPS between local nodes left as-is — already tracked as
an accepted, in-scope-for-now item in the vault's
`project_n8n_client_ready_roadmap` memory.

## Where I'm at right now (update, 2026-07-15)
Full security audit (all 3 n8n portfolio pieces, at Hunter's request)
found and fixed 2 real issues here: the webhook token had been shown at
length in a Claude Code session transcript, so treated as burned and
rotated (old token now gets `403`, confirmed live); and a 10 req/min
rate limiter was added ahead of the Ollama call (Code node + IF, global
sliding window — not per-IP, n8n's Webhook node doesn't cleanly expose
caller IP to a Code node). Full findings + fixes across all 3 projects:
vault root `playbooks/fixes-log.md`. Verified end-to-end against a real
Airtable write (`execution_entity.status='success'`, not just "no
error") after re-wiring the Airtable nodes' Base/Table pickers by hand
in the UI — required again because the audit also caught (and
sanitized) real Airtable IDs that had leaked into `workflow.json`'s
committed form; see `lead-qualifier-crm`'s CONTEXT.md for that finding,
which applied to this project too since both share the pattern.

## Where I'm at right now (update, 2026-07-14)
Gave this a real front door and back door instead of the scrapped video
demo (see root CONTEXT.md and `playbooks/demo-recording.md`'s "Strategy
update"):
- `demo-form.html` (gitignored, real token; `demo-form.example.html` is
  the committed template) — a "Harbor & Co." contact form that POSTs
  straight to the webhook using the existing header-auth token. Opens
  standalone via plain double-click, no server needed (confirmed n8n's
  webhook responds to the `null` origin `file://` pages send, via a
  direct CORS preflight check).
- Output moved from local `review-queue/`/`flagged/` files to a new
  Airtable table (`Inquiries`, same base as the Leads table) - added a
  "Format for Airtable" Code node and an If node routing on `valid`
  into two new Airtable Create nodes ("Needs Review" / "Flagged").
- Tested for real 3 times (2 via curl, 1 through an actual browser
  submitting the real form): a clean inquiry (correctly classified
  "general", landed as Needs Review), a prompt-injection attempt asking
  for an exact price (model complied and quoted $4,995-$9,995,
  validation caught it, landed as Flagged), and an urgent complaint
  (correctly classified, though the model hallucinated a wrong name in
  the reply - a real, honest model-quality quirk worth knowing about,
  not a validation gap since name-accuracy isn't a rule that's checked).
- Hit a real, since-fixed n8n bug along the way (this n8n version has a
  separate draft/published-version model; `update:workflow --active`
  doesn't reliably republish) - full writeup in the vault's
  `playbooks/fixes-log.md` and `playbooks/automation-platforms.md`.

## Where I'm at right now (update, 2026-07-13)
Closed the auth gap flagged 2026-07-12: generated a real token, created
`credentials.json` (gitignored, matches `credentials.example.json`'s
id/name so it auto-attaches to the Webhook node) and imported it with
`npx n8n import:credentials`. Confirmed live: a request without
`X-Webhook-Token` gets a clean `403`, a request with the correct token
runs the full pipeline and returns `200`.
Also hit and fixed a second, unrelated bug while testing this: n8n
2.29.10 now blocks `fs`/`path`/`os` in Code nodes by default
("Module 'fs' is disallowed"), which broke the final
"Write to Review Queue or Flagged" step. Fixed with
`NODE_FUNCTION_ALLOW_BUILTIN=fs,path,os` at n8n startup — this was
already documented in the vault's `playbooks/fixes-log.md` from an
earlier encounter on `lead-qualifier`, just hadn't been applied to this
environment yet.

Later the same day: pulled into a Terry Studio demo-recording session
(Goal 1) that was ultimately scrapped by Hunter as unusable — see vault
root CONTEXT.md and `playbooks/demo-recording.md` for what was learned.
The `demo/` and `demo-inquiries/` folders created for it have been
deleted (scratch work, not shipped project content). No video exists
from this session. The auth-credential and env-var fixes above are
still real and still in place.

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
