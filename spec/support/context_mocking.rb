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

  def stubbed_context_instantiation(**attrs)
    mock_context(**attrs).tap do |fake|
      allow(RSpec::CoverIt::Context).to receive(:new).and_return(fake)
    end
  end
end

RSpec.configure do |config|
  config.include ContextMocking
end
