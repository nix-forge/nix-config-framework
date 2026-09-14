# Threat model

## Scope

This model covers the framework library, target discovery, selector and module
contracts, documentation site, tests, and repository automation. It does not
cover a consumer's host, credentials, hardware, or downstream modules.

## Assets and actors

Assets include exported module interfaces, target metadata, dependency pins,
generated documentation, and CI access. Contributors and pull requests are
untrusted. Maintainers approve changes and control repository, Pages, Actions,
and source release settings. Consumers control their own target files and
deployment policy.

## Trust boundaries

The framework evaluator, consumer configuration, generated outputs, and GitHub
Actions are separate boundaries. Discovery must not execute or expose private
consumer files beyond the intended repository root. Pull-request jobs must not
receive repository secrets.

## Main threats and controls

| Threat | Control |
| --- | --- |
| Discovery imports an unintended file | Explicit layout contract, selector tests, and path validation |
| A module change breaks consumers silently | Focused fixtures, flake checks, compatibility docs, and required review |
| CI executes untrusted input with write access | Empty default permissions, job scopes, pinned actions, and no fork secrets |
| A dependency introduces a known flaw | Lockfile review, dependency review, CodeQL, and release gating |

## Assessment cadence

Before each source release, and whenever discovery, exported interfaces, or a
trust boundary changes, maintainers review the framework's attack surface,
external Nix and GitHub interfaces, and the critical paths above. The review
records changed threats, required tests, and any release limitation in the
pull request or release notes.

Review this model when discovery, exported interfaces, dependency trust, CI, or
release behavior changes.
