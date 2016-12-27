require 'test_helper'
require 'generators/make_associations_complete/make_associations_complete_generator'

class MakeAssociationsCompleteGeneratorTest < Rails::Generators::TestCase
  tests MakeAssociationsCompleteGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
