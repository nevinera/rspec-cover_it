require_relative "lib/rspec/cover_it/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-cover_it"
  spec.version = RSpec::CoverIt::VERSION
  spec.authors = ["Eric Mueller"]
  spec.email = ["nevinera@gmail.com"]

  spec.summary = "A system to enforce test coverage on each class"
  spec.description = <<~DESC
    We're all used to tools that enforce _total_ coverage numbers, but this gem
    tries for something different. Instead of keeping your whole project above
    some threshold, we treat the coverage of _each class_ as a testable quality
    and then enforce that coverage as part of the test suite!
  DESC
  spec.homepage = "https://github.com/nevinera/rspec-cover_it"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.require_paths = ["lib"]
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.start_with?("spec") }
  end

  spec.add_dependency "rspec", "~> 3.10"

  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "standard", "~> 1.28"
  spec.add_development_dependency "rubocop", "~> 1.28"
  spec.add_development_dependency "mdl", "~> 0.12"
  spec.add_development_dependency "quiet_quality", "~> 1.2"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
end
