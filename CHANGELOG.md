# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- CI check (`scripts/check.sh`, run on every pull request and on push to `main`) that
  verifies the skills fit together: valid `SKILL.md` frontmatter, alias targets that
  exist, and an OpenCode command for every skill.
- `implement-issue` now adds a changelog entry, in the same commit as the code, when the
  target repo keeps one.
