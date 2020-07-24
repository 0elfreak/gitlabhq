# Updating to GitLab 13.2: Email confirmation issues

In the [GitLab 13.0.1 security release](https://about.gitlab.com/releases/2020/05/27/security-release-13-0-1-released/),
we described a security issue that allowed users to bypass the email verification process.
In that notice, we strongly recommended that you upgrade all affected installations to the
latest version as soon as possible.

There is a chance that users on a self-managed instance may be unable to commit code and
sign in. For more information, see the following resolved and closed
[security issue](https://gitlab.com/gitlab-org/gitlab/-/issues/121664).

This page can help you identify the users at risk, as well as potential issues of the update.

## The risk: users get emails that require confirmation

During the update process to GitLab 13.2, a background migration is run for accounts that meet the
conditions for the security issue. Such users are marked as _unconfirmed_.

An initial email is sent to _unconfirmed_ users to describe the issue. A second email is then
sent within five minutes, with a link for users to re-confirm the subject email address.

## Do the confirmation emails expire?

The links in these re-confirmation emails expire after one day by default. Users who click an expired link will be asked to request a new re-confirmation email. Any user can request a new re-confirmation email from `http://gitlab.example.com/users/confirmation/new`.

## Generate a list of affected users

You can generate this list before and after the upgrade using different methods.

### Before an upgrade to GitLab 13.2

Use the following code to search for users who:

- Are currently confirmed.
- Include identical `confirmed_at` times.
- Also have a secondary email address.

```ruby
emails_and_users_that_will_be_unconfirmed = Email.joins(:user).merge(User.active).where('emails.confirmed_at IS NOT NULL').where('emails.confirmed_at = users.confirmed_at').where('emails.email <> users.email')
```

### After an upgrade to GitLab 13.2

Use the following code to search for users who:

- Are currently **not** confirmed.
- Are also pending confirmation on or after the date of upgrade.

```ruby
users_apparently_pending_reconfirmation = User.where(confirmed_at: nil).where('confirmation_sent_at >= ?', date_of_upgrade_to_13_2)
```

## What does it look like when a user is blocked?

A regular user might receive a message that says "You have to confirm your email address before continuing". This message could includes a 404 or 422 error code, when the user tries to sign in.

NOTE: **Note:**
We hope to improve the [sign-in experience for an unverified user](https://gitlab.com/gitlab-org/gitlab/-/issues/29279) in a future release.

When an affected user commits code to a Git repository, that user may see the following message:

```shell
Your account has been blocked. Fatal: Could not read from remote repository
```

You can assure your users that they have not been [Blocked](admin_area/blocking_unblocking_users.md) by an administrator.
When affected users see this message, they must confirm their email address before they can commit code.

## What do I need to know as an administrator of a GitLab Self-Managed Instance?

You have the following options to help your users:

- They can confirm their address through the email that they received.
- They can confirm the subject email address themselves by navigating to `https://gitlab.example.com/users/confirmation/new`.

As an administrator, you may also confirm a user in the [Admin Area](admin_area/#administering-users).

## What do I do if I am an administrator and I am locked out?

If you are an administrator and cannot otherwise verify your email address, sign in to your GitLab
instance with a [Rails console session](../administration/troubleshooting/navigating_gitlab_via_rails_console.md#starting-a-rails-console-session).
Once connected, run the following commands to confirm your administrator account:

```ruby
admin = User.find_by_username "root" #replace with your admin username
admin.confirmed_at = Time.zone.now
admin.save!
```

## What about LDAP users?

LDAP users should NOT be affected.