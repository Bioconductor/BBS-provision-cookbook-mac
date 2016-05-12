#require 'spec_helper'
#require_relative '../../../kitchen/data/spec_helper'
# require_relative '/tmp/verifier/suites/serverspec/spec_helper'
# require_relative './spec_helper'
require_relative '/tmp/kitchen/data/spec_helper'


## IMPORTANT: We are not using these tests anymore. instead
## we are using control groups in the recipe.

describe "BBS-provision-cookbook::default" do
  # describe package('git') do
  #   it {should be_installed}
  # end


  describe file('/etc/timezone') do
    its(:content) {should_not match /UTC|GMT/}
  end

  describe file('/etc/passwd') do
    its(:content) {should match /biocbuild/}
  end


end
