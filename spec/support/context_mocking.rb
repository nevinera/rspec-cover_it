module ContextMocking
  def mock_context(**attrs)
    defaults = {
      specific_threshold: 1.0,
      scope_name: "fake/path_spec.rb",
      target_class: Object,
      target_path: "fake/path.rb"
    }
    mocked_methods = defaults.merge(attrs)
    instance_double(RSpec::CoverIt::Context, **mocked_methods)
  end
end

RSpec.configure do |config|
  config.include ContextMocking
end
