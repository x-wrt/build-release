# How to build x-wrt for your devices


## Don't use this branch, it is used to build x-wrt for ALL platform with parallel jobs

Maintainers run this branch on Linux with Git, Python 3, zip, and the usual
OpenWrt build tools. Each `BTARGET=` line in `target.list` creates a job; multiple
space-separated targets on one line share a job.

Set `release.tag` to the upstream X-WRT tag without the release `v` prefix.
Tags may contain letters, digits, dots, underscores, and hyphens. The generator
reads configurations from `../feeds/x/rom/lede` by default; set
`RELEASE_CONFIG_DIR` to use another configuration directory.

Generate the workflow locally for review:

```
sh update-tags.sh --generate-only
sh update-tags.sh --generate-only airoha-an7581
```

The optional target selector matches a full target name and includes its entire
job. Generation replaces `.github/workflows/release.yml` only after every
selected configuration has been read successfully. Duplicate targets, job names,
and release asset names are rejected. Group whitespace is normalized, and dots
in target names become underscores in job identifiers.

The workflow uses the runner's GitHub CLI to create or update the release and
upload each build job's exact asset list in one batch. Configure `WORKFLOW_TOKEN`
with permission to write repository contents. The workflow's `GITHUB_TOKEN` has
read-only contents access, and checkout does not persist credentials. Runs for
the same release tag are serialized to prevent overlapping uploads. The pushed
tag must match `v<release.tag>` in the generated workflow.

Disk cleanup removes only named, unused SDK directories. Runner installations,
action caches, and Node runtimes are retained so post-job actions can still run.

Failed builds save the complete console output as `build.log` and the diagnostic
`make.log`, when available, in a `build-failure-log-<target>` Actions artifact.

To publish a new version, commit script/template changes first, update
`release.tag`, then run `sh update-tags.sh` on `parallel-jobs`. This commits only
the generated workflow and `release.tag`, creates `v<release.tag>`, and pushes
the branch and that tag together with `git push --atomic`. Existing tags are
rejected before committing. Other modified and staged files are preserved.

Packaging selects firmware by target and device, and application packages by
target and architecture. Device ZIPs contain a download index and checked
SHA-256 sums. Archives are created from fresh temporary directories, so a
rerun replaces old ZIP contents and leaves existing `rom/` files in place.

Run the isolated regression tests with:

```
python3 -m unittest discover -s tests -v
TEST_SHELL='busybox ash' python3 -m unittest discover -s tests -v
```

Tests use temporary build trees and local Git remotes. They do not build
firmware, install software through sudo, or push to GitHub.
