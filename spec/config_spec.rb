require 'spec_helper'
require 'config'

describe EcMetal::Config, "provider type and options" do
  it "defaults to ec2 with ec2 options" do
    expect(EcMetal::Config.provider.type).to eq('ec2')
  end
end