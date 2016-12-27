require 'test_helper'
require 'generators/thecoreize_rails_plugin/thecoreize_rails_plugin_generator'

class ThecoreizeRailsPluginGeneratorTest < Rails::Generators::TestCase
  tests ThecoreizeRailsPluginGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
