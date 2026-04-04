# Security Notes and Triage Policy

This repository primarily contains educational/lab artifacts (not a single production application).

## Current Dependabot context

At the time of writing, open alerts are concentrated in legacy Falcor demo dependency trees:

- `Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/falcor-express-demo/package-lock.json`
- `Edx-Courses/LFS141x-exploring-graphql/factor-express-demo/falcor-app-server/package-lock.json`

These are course/demo dependencies and may include intentionally old packages used for learning exercises.

## Triage checklist (UI workflow)

Use this checklist when reviewing GitHub Dependabot alerts in the Security tab.

1. Confirm the alert is tied to a legacy demo manifest path above.
2. Confirm the dependency is not used by root-level automation scripts (`lab-run.sh`, `lab-cleanup.sh`) or CI/CD infra.
3. Determine runtime exposure:
   - If only used in local demo coursework and not deployed externally, classify as `legacy-demo`.
4. For `legacy-demo` findings, dismiss with a clear rationale:
   - Suggested reason: `risk accepted` or `not used in production`.
   - Suggested comment:
     - `Legacy educational dependency in Falcor demo coursework. Not used in production services; tracked here for historical/lab compatibility.`
5. If an alert affects actively used runtime code, do not dismiss; open an issue/PR to update dependencies.

## Recommended minimal triage order

To quickly reduce high-noise alerts while preserving traceability:

1. `critical`
2. `high`
3. `medium`
4. `low`

Apply the same comment template for consistency.

## Optional CLI aid

After `gh auth login`:

```bash
gh api "repos/kernel528/edx.org/dependabot/alerts?state=open&per_page=100" \
  --jq '.[] | [.number, .security_advisory.severity, .dependency.package.name, .dependency.manifest_path] | @tsv'
```

## Reporting new security issues

If you find a vulnerability that appears to affect non-demo/runtime code paths, open a private security advisory or issue with:

- affected path(s)
- package + version
- exploitability notes
- recommended fix path
