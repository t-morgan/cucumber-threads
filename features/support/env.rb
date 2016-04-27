AfterConfiguration do |config|
  config.filters << Cucumber::Core::Test::ThreadFilter.new
end