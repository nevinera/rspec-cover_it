module Fine
  # Define Bar ahead of time, so ruby thinks it's defined _here_, and we can
  # correct that in the spec using covers_path
  class Bar
  end
end

glob = File.expand_path("../fine/*.rb", __FILE__)
Dir.glob(glob).sort.each { |f| require f }
