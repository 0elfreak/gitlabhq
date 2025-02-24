---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
comments: false
---

# Merge conflicts **(FREE)**

- Happen often
- Learning to fix conflicts is hard
- Practice makes perfect
- Force push after fixing conflicts. Be careful!

## Merge conflicts sample workflow

1. Check out a new branch and edit `conflicts.rb`. Add 'Line4' and 'Line5'.
1. Commit and push.
1. Check out `main` and edit `conflicts.rb`. Add 'Line6' and 'Line7' below 'Line3'.
1. Commit and push to `main``.
1. Create a merge request and watch it fail.
1. Rebase our new branch with `main`.
1. Fix conflicts on the `conflicts.rb` file.
1. Stage the file and continue rebasing.
1. Force push the changes.
1. Finally continue with the merge request.

```shell
git checkout -b conflicts_branch

# vi conflicts.rb
# Add 'Line4' and 'Line5'

git commit -am "add line4 and line5"
git push origin conflicts_branch

git checkout main

# vi conflicts.rb
# Add 'Line6' and 'Line7'
git commit -am "add line6 and line7"
git push origin main
```

Create a merge request on the GitLab web UI, and a conflict warning displays.

```shell
git checkout conflicts_branch
git fetch
git rebase main

# Fix conflicts by editing the files.

git add conflicts.rb
# No need to commit this file

git rebase --continue

# Remember that we have rewritten our commit history so we
# need to force push so that our remote branch is restructured
git push origin conflicts_branch -f
```

## Note

- When to use `git merge` and when to use `git rebase`
- Rebase when updating your branch with `main`
- Merge when bringing changes from feature to `main`
- Reference: <https://www.atlassian.com/git/tutorials/merging-vs-rebasing>
