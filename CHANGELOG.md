# Changelog

## 0.2.0 — 2026-09-22

- Add `:DodonaResult [id]` to show submission feedback in a right-hand split,
  including test totals, scores, runtime, failed tests and judge messages.
  Use `q` to close and `r` to refresh without submitting again.
- Run submissions and polling asynchronously, with a 60-second polling deadline.
- Report HTTP failures and malformed API responses without uncaught Lua errors.
- Hide token input, store tokens with restrictive permissions, and pass tokens
  and submitted code to curl through stdin.
- Validate configured server URLs and exercise IDs; make repeated setup calls
  replace the previous configuration.
- Improve health checks and defer loading submission modules until use.

## 0.1.0

- Initial release with `:DodonaSubmit`, `:DodonaSetToken` and `:DodonaHealth`.
