# Examples

Each directory is self-contained and runnable. Every demo makes real calls to the
on-device model, so expect a minute or two each. Nothing outside this checkout is
modified. The route handlers only narrate.

```sh
examples/demo.sh              # all of them, in order
examples/routing/demo.sh      # or one area on its own
```

| Directory | What it shows |
|---|---|
| [`routing/`](routing/) | The semantic router: `--route`, `priority`, `all_of`, `--dry-run` |
| [`schema/`](schema/) | Structured extraction — `--schema` as a value producer, not a predicate |
| [`json/`](json/) | The `--json` interface, and chaining it with `jq` |
| [`workflows/`](workflows/) | End-to-end scripts worth copying: CI triage, diff review |

---

## routing/

`routes.json` declares six routes plus a fallback, several of them deliberately
overlapping:

```json
{ "name": "dependency-security",
  "when": "a dependency problem that also involves a security vulnerability",
  "all_of": ["dependency", "security"],
  "priority": 100,
  "run": ["./handle-dependency-security.sh"] }
```

The demo shows the model reporting *both* `dependency` and `security`, and the engine
then deriving `dependency-security` and letting its priority win. That split is the
whole design: the model says what is true, the engine decides what that implies and
which command runs.

`--dry-run` prints the decision and executes nothing — the mode to sit in while you are
still tuning your `when` text.

**Note on paths:** `run` is resolved against the current directory, so `routes.json`
names its handlers as siblings. Each demo `cd`s into its own directory first. In your
own project, either do the same or use absolute paths.

## schema/

`--schema` turns `fmevent` from a yes/no question into an extractor. There is no
true/false, so it is not a predicate: the exit status is 0 when valid JSON came back
and 2 when it did not.

Two schemas are provided:

- `change.json` — classify a diff (one object, one verdict)
- `findings.json` — summarise a log (an object containing a list)

The demo ends by piping `.findings[]` into a `while read` loop, which is the point:
the model's output is a value you can hand to the tools you already use.

`x-order` in the schema fixes the order the model writes fields in. Put descriptive
fields before judgement fields — the model commits to what it has already written, so
a verdict that precedes its reasoning is a worse verdict.

## json/

`--json` is what makes `fmevent` usable inside a program rather than just inside an
`if`. The demo covers the three-field shape (`matched`, `confidence`, `evidence`), the
invariant that the exit status and `.matched` always agree, and three ways of chaining
it with `jq`.

Remember that `confidence` is the model's *self-report*, not a calibrated probability.
It is there to be inspected and calibrated against your own data, not trusted as a
number.

## workflows/

Two scripts to copy into a CI job:

**`triage-ci.sh`** runs a command, captures its output with `2>&1`, and routes the
failure:

```sh
$ examples/workflows/triage-ci.sh
$ sh -c echo "pip install failed: could not resolve dependency numpy==9.9.9" >&2; exit 1
command failed (exit 1). What kind of failure is this?

    | pip install failed: could not resolve dependency numpy==9.9.9

DEPENDENCY FAILURE -- would retry the install with a clean resolver cache

dispatched.
```

Run with no arguments and it demonstrates itself; pass a command
(`triage-ci.sh make test`) to triage the real thing.

It distinguishes all three outcomes — routed, nothing matched, and `fmevent` itself
failed — so a broken model never looks like a clean "no problem here".

**`review-diff.sh`** gates a change on whether it touches authentication or
cryptography, and exits 1 so it fails a build:

```sh
$ git diff | examples/workflows/review-diff.sh -
{
  "summary": "The code checks if the password matches the stored password using a constant-time comparison.",
  "severity": "high",
  "category": "authentication",
  "security_sensitive": true
}

This change alters authentication. Requesting a security review.
```

The policy is a `jq` expression, not a prompt. The model reports what the diff
contains; the decision about what that means is a line of inspectable code that no
clever diff can argue with.

Both scripts pass `--greedy`, because a route that changes between runs of the same
build is not one you can automate on.
