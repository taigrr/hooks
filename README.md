# hooks

This is a collection of simple git hooks I use on my own system.
Many people don't like git hooks these days, usually because they're slow.
If your git hooks are slow, your commits slow down and start to cause development
friction, which is to be avoided.

These hooks are simple and aim to add no more than a few milliseconds to your commits.
For example, using git-lfs hooks can cause some slowdowns on repos which aren't actually
lfs-enabled, but adding lfs support to repos which already have hooks installed
is an annoying extra step, so `git lfs track` is used to short-circuit this logic.

These hooks presume a couple of pre-installed binaries:

- git (duh)
- git-lfs
- [gitleaks](https://github.com/gitleaks/gitleaks)
- [mg](https://github.com/taigrr/mg)

## What these hooks do

Rather than try to lint code from a git hook, or run tests, etc., these hooks
assume you're already a good developer. You know how to follow style guides,
you're ok with an occasionaly failing CI job. That's what CI is for, after all.

These hooks don't try to hold your hand, they just prevent accidentally making
a couple of annoying blunders:

1. Automatically configure LFS hooks for new repos
1. Warn the user when a file over a certain filesize limit is added to the repo
1. Scan the staged files for added secrets (using the fantastic gitleaks tool)
1. On a push, register the repo with Magnesium, (mg) my git repos management cli.

## Installation
### Template Installation
1. Clone this repo somewhere on your system.
1. Configure git to use these hooks as your template hook directory by adding this line to your global git config: `git config --global init.templatedir` 

### Central Management Installation 
Alternatively, you can use the hook directory as-is, instead of copying the hooks into every repo.
Run this command:
1. `git config --global core.hooksPath /path/to/my/centralized/hooks`

This has the benefit of updating the hooks for all repos when you make a change, instead of only new repos going forward, but will require you to specify manual overrides for individual repos with customized hooks.

## Compatability Notice
These hooks are not tested alondside any other hooks, or 'hook managers' such as pre-commit or Husky.

They will almost certainly cause issues if used alongside git-annex.
You have been warned.

## Contributing
Keeping in mind that the hooks are supposed to be extremely generic and fast, I
don't know what else there might be to add, but if there's something you think 
I'm missing feel free to open a PR and I'll consider it.
