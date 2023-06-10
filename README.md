# RSpec::CoverIt

The standard approach to monitoring "test coverage" in ruby is a tool called
[SimpleCov](https://github.com/simplecov-ruby/simplecov), and a variety of
systems made to hook into its output, to display a single number that represents
how much of your _total code_ is executed during your test suite. You set up
SimpleCov, and then you commit your team to maintaining whatever test coverage
number you already have achieved globally, or to improving that coverage number.
If you have one of the better tools, you can commit to things like "all merged
PRs should have 100% (or 95%, etc) coverage on all of their touched code."

That's.. better than nothing. A lot better - it can especially tell you when you
forgot to write tests for some component, or when you're adjusting a class that
doesn't have any tests written for it. But it's _not great_, not compared to a
system like RSpec that lets you specify with _granularity_ how things should
behave. The problem with SimpleCov is that it's _holistic_ - you can't adopt
simplecov one class at a time, or enforce full coverage on new code _in your
CI system_, you need external tooling with state persistence for that.

`RSpec::CoverIt` takes a different approach, somewhat inspired by the
[rspec-coverage](https://github.com/jamesdabbs/rspec-coverage) gem (which was
itself apparently inspired by a rubyconf-2016 talk by Ryan Davis). With CoverIt,
coverage-enforcement happens as part of your test-suite, enforced by rspec
either globally or as specified.

## Installation and Setup

Add the gem to your Gemfile or gemspec just like `simplecov` or `rspec`. Then
in your `spec_helper.rb`, _before_ you require your application or gem code,
require `rspec/cover_it`, and then invoke `RSpec::CoverIt.setup`, with the
appropriate options to configure it (described further down). A reasonable
initial setup might look like this:

```
require "rspec/cover_it"
project_root = File.expand_path("../..", __FILE__)
RSpec::CoverIt.setup(filter: project_root, autoenforce: true)

require File.expand_path("../../lib/my_gem", __FILE__)
```

## Configuration and Usage

When invoking `RSpec::CoverIt.setup`, you may supply these options:

* `filter`: Don't track coverage information about files that don't start with
  this prefix - this is largely a performance optimization, allowing the pretest
  coverage tracking to track information only about the current project, and not
  the various gems it might depend on.
* `autoenforce`: This is off by default, which means that coverage-enforcement
  will only be applied to top-level example groups that _request_ it, by
  supplying the `cover_it: true` spec metaddata. If you configure `autoenforce`
  to be `true`, then all specs will attempt to enforce coverage, as long as they
  can figure out their targets (unless they are told not to).

When setting up a test file, you can configure some additional details for that
example group - `CoverIt` is aware of the following bits of spec metadata:

* `cover_it`: If supplied with a truthy value, it activates coverage enforcement
  for this example-group - if supplied with a falsey value, it _deactivates_
  enforcement. If supplied with a _numeric_ value, it is treated as a percentage,
  and used to configure the target coverage threshold for the class' definition,
  a feature which I intend not to use, but I expect some people to care deeply
  about.
* `covers_path`: in certain cases, a class or module may be "defined" in several
  locations. While actually enforcing coverage for multiple code files from one
  test file isn't yet implemented, if `rspec-cover_it` infers the location of
  the code under test _incorrectly_, you can tell it where to actually enforce
  coverage against by supplying a path here (relative to the directory
  containing the test file).

## Implementation Approach

When setting up the tool, we activate the built-in ruby Coverage system (we
start it in legacy-supporting mode, but we are compatible with it having already
been started in the more modern mode as well). Then we register three rspec
hooks:

* Before the suite _starts_ (which should be after everything is loaded), we
  record the coverage _so far_ - this is the 'initialization' coverage, which
  mostly includes the lines that run during class evaluation.
* Before each 'context' (spec file), we record the coverage information
* After each 'context' we record the coverage information _again_. Then we
  subtract the two sets of coverage, which tells us how many times each line
  was run _during this example group_, and add it to the 'initialization'
  coverage to see the effective coverage for just this test file.

Then, for each test file, we use ruby's source-introspection system to tell
us where the "described class" was defined, and check what fraction of that
source file is effectively covered by this example group. If there is some
missing coverage, we raise an exception explaining the missing coverage.

But of course, if you only run part of the tests in a spec file (perhaps by
specifying a line number, or a description filter with `-e`), it probably won't
be fully covered. We don't want to fail the test suite every time you're working
on the specs for something, so we reach into RSpec a little to check if the
set of _filtered_ examples (the ones being run) match the _full_ set of
examples. If they don't, don't bother checking coverage for this test file.

## Caveats and Shortcomings

For the moment, there is no support for _autoloading_, which makes this library
awkward to use for the majority of large rails applications. I intend to resolve
this issue soon, but it's not a trivial one, as coverage-tracking on a per-spec
basis relies on being able to separate coverage that happens during code-loading
from coverage that happens during "tests other than this spec which have already
occurred" - we'll need to add some kind of autoloading hooks to support it
properly.

Until then, the gem will only be useful to a rails application in an eager-
loaded context - that's not a major issue in CI, but it's awkward when running
tests locally. Happily, `rspec-cover_it` is fully compatible with `simplecov`
(though you do need to start `SimpleCov` _before_ `Rspec::CoverIt`), so you can
simply use simplecov locally when resolving coverage issues (or set up eager-
loading locally based on an environment variable, the solution I prefer), and
still use `RSpec::CoverIt` to enforce coverage in your CI system.
