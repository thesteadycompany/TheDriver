# Contributing

## Commit Messages

Use a simple, verb-first message in English.

**Format**

```
<Verb> <Target>
```

**Rules**
- Start with a capitalized verb (imperative mood).
- Keep it short (<= 72 characters).
- No prefixes or scopes (avoid `feat:`, `fix:`, etc.).
- No trailing period.
- One logical change per commit.

**Recommended verbs**
- Add, Update, Fix, Remove, Refactor, Rename, Move, Revert, Docs, Test

**Examples**
- Add shared running app logging
- Update DeviceLogging UI
- Fix AppCenter launch flow
- Refactor SimulatorClient logging predicate

## Do Not Commit

Follow the repository rules in `AGENTS.md` (generated build artifacts, user-local Xcode state, etc.).
