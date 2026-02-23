# hooks

A collection of simple, fast git hooks for everyday use.

Many people don't like git hooks these days, usually because they're slow.
If your git hooks are slow, your commits slow down and start to cause development
friction, which is to be avoided.

These hooks are simple and aim to add no more than a few milliseconds to your commits.
For example, using git-lfs hooks can cause some slowdowns on repos which aren't actually
lfs-enabled, but adding lfs support to repos which already have hooks installed
is an annoying extra step, so `git lfs track` is used to short-circuit this logic.

## Prerequisites

- [git](https://git-scm.com/)
- [git-lfs](https://git-lfs.github.com/)
- [gitleaks](https://github.com/gitleaks/gitleaks)
- [mg](https://github.com/taigrr/mg) (optional, for repo registration on push)

## What these hooks do

Rather than try to lint code from a git hook, or run tests, etc., these hooks
assume you're already a good developer. You know how to follow style guides,
you're ok with an occasionally failing CI job. That's what CI is for, after all.

These hooks don't try to hold your hand, they just prevent accidentally making
a couple of annoying blunders:

| Hook | What it does |
|------|-------------|
| `pre-commit` | Blocks commits containing files over 5 MB (unless tracked by LFS) |
| `pre-commit` | Scans staged files for leaked secrets via gitleaks |
| `post-checkout` | Runs `git lfs post-checkout` |
| `post-commit` | Runs `git lfs post-commit` |
| `post-merge` | Runs `git lfs post-merge` |
| `pre-push` | Registers the repo with mg, then runs `git lfs pre-push` if LFS is active |

## Installation

### Quick Install

```bash
git clone https://github.com/taigrr/hooks.git ~/.git-hooks
git config --global core.hooksPath ~/.git-hooks
```

### Template Installation

Use this if you want new repos to get a *copy* of the hooks at clone/init time:

```bash
git clone https://github.com/taigrr/hooks.git ~/.git-hooks
git config --global init.templatedir ~/.git-hooks
```

> **Note:** Existing repos won't be affected — only newly cloned or initialized repos
> will receive the hooks.

### Central Management Installation

Use this if you want *all* repos (existing and new) to use the same hooks directory:

```bash
git clone https://github.com/taigrr/hooks.git ~/.git-hooks
git config --global core.hooksPath ~/.git-hooks
```

This has the benefit of updating the hooks for all repos when you make a change,
instead of only new repos going forward, but will require you to specify manual
overrides for individual repos with customized hooks:

```bash
# Override for a specific repo
cd /path/to/repo
git config core.hooksPath /path/to/other/hooks
```

## Configuration

The file size limit in `pre-commit` defaults to **5 MB**. To change it, edit the
`size_limit` variable at the top of the `pre-commit` file:

```bash
size_limit=$((10 * 2**20))  # 10 MB
```

## Compatibility Notice

These hooks are not tested alongside any other hooks, or "hook managers" such as
pre-commit or Husky. They will almost certainly cause issues if used alongside
git-annex. You have been warned.

## Contributing

Keeping in mind that the hooks are supposed to be extremely generic and fast, I
don't know what else there might be to add, but if there's something you think
I'm missing feel free to open a PR and I'll consider it.
