# Governance

`nix-config-framework` is a maintainer-led open source project. The current
maintainer is [@IanHollow](https://github.com/IanHollow).

The project is a reusable framework, not a host configuration. Changes should
keep the discovery and module-selection contracts explicit, preserve consumer
compatibility where practical, and document intentional breaking changes.

Issues and pull requests are the public record for technical decisions. The
protected `main` branch, required checks, review rules, and merge queue apply to
all accepted changes.

Code collaborators are reviewed before receiving escalated permissions for
protected-branch approval, repository administration, Pages, Actions secrets,
or release automation. The review considers sustained contribution quality,
identity or organizational affiliation where relevant, and the narrowest role
needed. Access is revisited when responsibility changes and removed promptly
when it ends.

The maintainer makes release and compatibility decisions. New maintainers may
be invited after sustained, constructive contributions and agreement on the
project's security and support expectations.

Report security issues through [SECURITY.md](SECURITY.md), not through public
issues or pull requests.
