# bundle_update_interactive

[![Gem Version](https://img.shields.io/gem/v/bundle_update_interactive)](https://rubygems.org/gems/bundle_update_interactive)
[![Gem Downloads](https://img.shields.io/gem/dt/bundle_update_interactive)](https://www.ruby-toolbox.com/projects/bundle_update_interactive)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/mattbrictson/bundle_update_interactive/ci.yml)](https://github.com/mattbrictson/bundle_update_interactive/actions/workflows/ci.yml)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/mattbrictson/bundle_update_interactive)](https://codeclimate.com/github/mattbrictson/bundle_update_interactive)

**This gem adds an `update-interactive` command to [Bundler](https://bundler.io).** Run it to see what gems can be updated, then pick and choose which ones to update. If you've used `yarn upgrade-interactive`, the interface should be very familiar.

<img src="images/update-interactive.png" alt="Screenshot of update-interactive UI" width="1154" />

---

- [Quick start](#quick-start)
- [Features](#features)
- [Prior art](#prior-art)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Quick start

Install the gem:

```
gem install bundle_update_interactive
```

Now you can use:

```
bundle update-interactive
```

Or the shorthand:

```
bundle ui
```

## Features

### Semver highlighting

`bundle update-interactive` highlights each gem according the severity of its version upgrade.

<img src="images/semver.png" alt="Severities are in red, yellow, and green" width="480" />

Gems sourced from Git repositories are highlighted in cyan, regardless of the semver change, due to the fact that new commits pulled from the Git repo may not yet be officially released. In this case the semver information is unknown.

`bundle update-interactive` also highlights the exact portion of the version number that has changed, so you can quickly scan gem version for important differences.

<img src="images/version-highlight.png" alt="Screenshot of highlighted version numbers" width="70" />

### Security vulnerabilities

`bundle update-interactive` uses [bundler-audit](https://github.com/rubysec/bundler-audit) internally to search for outdated gems that have known security vulnerabilities. These gems are highlighted prominently with white text on a red background.

<img src="images/security.png" alt="Screenshot of security vulnerability highlighted in red" width="402" />

Some gems, notably `rails`, are composed of smaller gems like `actionpack`, `activesupport`, `railties`, etc. Because of how these component gem versions are constrained, you cannot update just one of them; they all must be updated together.

Therefore, if any Rails component has a security vulnerability, `bundle update-interactive` will automatically roll up that information into a single `rails` line item, so you can select it and upgrade all of its components in one shot.

### Changelogs

`bundle update-interactive` will do its best to find an appropriate changelog for each gem.

It prefers the `changelog_uri` [metadata](https://guides.rubygems.org/specification-reference/#metadata) published in the gem itself. However, this metadata field is optional, and many gem authors do not provide it.

As a fallback, `bundle update-interactive` will check if the gem's source code is hosted on GitHub, and scans the GitHub repo for obvious changelog files like `CHANGELOG.md`, `NEWS`, etc. Finally, if the project is actively documenting versions using GitHub Releases, the Releases URL will be used.

If you discover a gem that is missing a changelog in `bundle update-interactive`, [log an issue](https://github.com/mattbrictson/bundle_update_interactive/issues) and I'll see if the algorithm can be improved.

### Git diffs

If your `Gemfile` sources a gem from a GitHub repo like this:

```ruby
gem "rails", github: "rails/rails", branch: "7-1-stable"
```

Then `bundle update-interactive` will show a GitHub diff link instead of a changelog, so you can see exactly what changed when the gem is updated. For example:

https://github.com/rails/rails/compare/5a8d894...77dfa65

Currently only GitHub repos are supported, but I'm considering adding GitLab and BitBucket as well.

### Conservative updates

`bundle update-interactive` updates the gems you select by running `bundle update --conservative [GEMS...]`. This means that only those specific gems will be updated. Indirect dependencies shared with other gems will not be affected.

<img src="images/conservative.png" alt="Screenshot of gems being updated" width="762" />

An exception is made for "meta gems" like `rails` that are composed of dependencies locked at exact versions. For example, if you chose to upgrade `rails`, the actual command issued to Bundler will be:

```
bundle update --conservative \
  rails \
  actioncable \
  actionmailbox \
  actionmailer \
  actionpack \
  actiontext \
  actionview \
  activejob \
  activemodel \
  activerecord \
  activestorage \
  activesupport \
  railties
```

## Prior art

This project was inspired by [yarn upgrade-interactive](https://classic.yarnpkg.com/lang/en/docs/cli/upgrade-interactive/), and borrows many of its interface ideas.

Before creating `bundle update-interactive`, I published [bundleup](https://github.com/mattbrictson/bundleup), a gem that serves a similar purpose but with a simpler, non-interactive approach.

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/mattbrictson/bundle_update_interactive/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!

To test your locally cloned version of `bundle update-interactive`, run `rake install`. This will install the gem and its executable so that you can try it out on other local projects.

Before submitting a PR, make sure to run `rake` to see if there are any RuboCop or test failures.
