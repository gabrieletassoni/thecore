require 'test_helper'
require 'generators/thecorize_app/thecorize_app_generator'

class ThecorizeAppGeneratorTest < Rails::Generators::TestCase
  tests ThecorizeAppGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
