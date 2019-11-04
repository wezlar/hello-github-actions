# Automated Branch Pull Requests

This action will open a pull request to master branch (or otherwise specified)
whenever a branch with some prefix is pushed to. The idea is that you can
set up some workflow that pushes content to branches of the repostory,
and you would then want this push reviewed for merge to master.

Here is an example of what to put in your `.github/main.workflow` file to
trigger the action.

The values provided in `env` are the defaults
```
workflow "Create Pull Request" {
  on = "push"
  resolves = "Create New Pull Request"
}

action "Create New Pull Request" {
  uses = "15gifts/github-actions/raise-pr-action@master"
  secrets = [
    "GITHUB_TOKEN"
  ]
  env = {
    BRANCH_FROM = "master"
    BRANCH_TO = "develop"
    PULL_REQUEST_TITLE="master -> develop"
    PULL_REQUEST_BODY: "This is an automated pull request to update `develop` with the latest code from `master`",
    PULL_REQUEST_DRAFT: "false"
  }
}
```

Environment variables include:

  - **BRANCH_FROM**: the branch to issue pull request from
  - **BRANCH_TO**: the branch to issue the pull request to. Defaults to develop.
  - **PULL_REQUEST_TITLE**: the title for the pull request  (optional)
  - **PULL_REQUEST_BODY**: the body for the pull request (optional)
  - **PULL_REQUEST_DRAFT**: should the pull request be a draft PR? (optional; unset defaults to `false`)

## Example use Case: Merge master to develop

If the branch is already open for PR, it updates it.
