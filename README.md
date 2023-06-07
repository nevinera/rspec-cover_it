# RSpec::CoverIt

Still a work in progress, but this gem is intended to give us a simpler and
more _targeted_ way to manage coverage. The usual system for a large project
is a single overarching SimpleCov target; with good tooling, there will be
something checking that all of the lines of each PR get covered by the tests
in that PR, and there are checks that the overall coverage number doesn't drop
too far.. but it's a _sloppy, messy, lossy_ approach. Code loses coverage,
code gets added with no tests, tests get removed and other code becomes less
covered, and a lot of the time, that's because the _coverage is a lie_.

Your coverage tool is telling you.. how many times each line of code _got run_
during your entire test suite. But it's not telling you what is doing the
running, which means that often large swathes of code are actually only covered
incidentally, through tests that aren't intended to exercise that code, but
_happens to_.

This approach was moderately inspired by https://github.com/jamesdabbs/rspec-coverage,
which was itself apparently inspired by a rubyconf 2016 talk by Ryan Davis. That
talk and library are mostly concerned with making sure that we don't _overcount_
coverage though, while this one has three goals:

1. Make coverage enforcement simpler
1. Enforce coverage _in the test suite_ (or nearly so)
1. Make coverage enforcement more local and specific.

## Tentative Usage

Note that this bit isn't really implemented, but is more of an outline of how I
intend the library to work. This is currently a spike, and not a functioning gem.

You set up `RSpec::CoverIt` in your `spec_helper.rb` - require `rspec/cover_it`,
and then `RSpec::CoverIt.setup(**config_options)` (before loading your code, as
you would with any other coverage library). It's.. _semi_ compatible with other
coverage systems - it only starts Coverage if it's not already running, and it
only uses `peek_result`, so it doesn't affect other systems outcomes.
Rough configuration options:

* `filter`: Only paths starting with this (matching this regex?) can matter
* `autoenforce`: off by default - with this disabled, you turn on coverage
  enforcement for a given top-level describe ExampleGroup by adding metadata
  like `cover_it: true` or `cover_it: 95`. If it's enabled though, you instead
  can turn enforcement _off_ for an example group by setting `cover_it: false`.
* `global_threshold`: 100% by default. This whole "90% coverage is the right
  target" thing is mostly a side-effect of the way we check the entire project
  under one number.. but it's an easy setting to support, and I'm sure people
  will disagree with me.

## Example Group Metadata

In example groups, you can use metadata to control the behavior of
`rspec-cover_it`. These keys have meaning:

* `cover_it`: if boolean, it enables or disables the coverage enforcement for
  this ExampleGroup. If numeric, it's enabling, and specifying the coverage
  threshold at the same time (as a percentage - `cover_it: 95` requires 95%
  coverage of the target class by this example group).
* `covers_path`: The path (relative to the spec file!) of the code the spec is
  intending to cover. Later, this can be an array of paths, for the multi-spec
  case `covers` is intended for as well. This is an annoying work-around for
  the fact that we can't perfectly infer the location of the source code in
  some cases - in particular, `lib/foo/version.rb` tends to cause a problem
  for specs on `foo.rb`, since the version file is invariably loaded first.
  Note - in gems, this _frequently_ also happens when you glob-load a directory
  _before_ defining the namespace they are all loading objects into. Then the
  first file in that directory that loads ends up being the one that actually
  creates the namespace.
* `covers`: An array of classes and modules that this example groups _thinks
  it is completely testing_. Ideally, you'd have a separate test file for each,
  but sometimes that's hard to do - you can let one spec claim responsibility
  for multiple classes and modules (such as Concerns) using this. Be default
  it is just `[described_class]`. Additionally, if your top-level example
  group _does not describe a Class or Module_, you may use `covers` to let it
  invoke `rspec-cover_it` anyway - some people `describe "a descriptive string"`
  instead of `describe AClass`, and .. fine.

## Implementation

We record the coverage information in a `before(:suite)` rspec hook using
`Coverage.peek_result`, and hold onto that information. Then before and after
each 'context' (which really amounts to 'each spec file'), we grab the coverage
information again.

We use `Object.const_source_location` to find the file that defines the
`described_class`, and _that_ is what is being assessed for coverage. This
means that, if you are reopening the class somewhere else, that coverage won't
be checked; if you are including 15 Concerns, and don't intend to write separate
specs for them, be sure to list them as `covers:` metadata on the test. Also,
shame!

## Output

When there's missing coverage on the class under test, you'll currently see
output like this:

```
❯ rspec

Randomized with seed 29392
...............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................
An error occurred in an `after(:context)` hook.
Failure/Error: fail(MissingCoverage, message)
  Missing coverage in /Users/emueller/src/quiet_quality/lib/quiet_quality/message.rb on line 7
# /Users/emueller/src/rspec-cover_it/lib/rspec/cover_it/context_coverage.rb:40:in `enforce!'
# /Users/emueller/src/rspec-cover_it/lib/rspec/cover_it/coverage_state.rb:37:in `block in finish_tracking_for'
# /Users/emueller/src/rspec-cover_it/lib/rspec/cover_it/coverage_state.rb:35:in `finish_tracking_for'
# /Users/emueller/src/rspec-cover_it/lib/rspec/cover_it.rb:26:in `block (2 levels) in setup'
.....................................................................................................................................................................................................................................................................................................

Finished in 1.06 seconds (files took 0.28925 seconds to load)
852 examples, 0 failures, 1 error occurred outside of examples
```

## Drawbacks and Shortcomings

There's nothing in here that stops you from failing to write tests for a class
at all! If you're using SimpleCov and you've got 100% coverage already, that's
one of the benefits.. I could pretty reasonably include some kind of
`after(:suite)` hook that optionally checks net coverage, but.. simplecov does
that, and the concurrent-testing game makes this a _painful_ topic in reality.
That's not the goal here, and I'm not going to worry about it.

As initially implemented, it fails your tests if you don't run the entire test
file. `rspec spec/foo_spec.rb:32` will error, because .. running only one of
your tests _doesn't cover the class_. I have a solution for this, but it uses
some non-public bits of RSpec, so I'm trying to find a better answer still.
(Conversation started in their
[issue tracker](https://github.com/rspec/rspec-core/issues/3037))

We're using `Object.const_source_location` to find the path of the source file
defining a given constant. That _mostly_ works, but it actually gives the path
of the _first_ source file that defined that constant. So if your gem defines
its version in `lib/foo/version.rb` (as an example), in a separate file from
lib/foo.rb, the _path_ for `Foo` may end up being the former. Which is.. not
going to have much coverable code, of course. This is an edge case, but one
that is likely to occur fairly regularly. I haven't thought of a _good_ solution
yet. Perhaps if the `covers` array includes a string, we should treat it as a
relative path?
