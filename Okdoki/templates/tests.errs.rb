
require './Server/MODEL/model'

describe "MODEL: !sub_action" do

  it "defines an Invalid exception" do
    MODEL.const_defined?(:Invalid).should.equal true
  end

  it "defines a Not_Found exception" do
    MODEL.const_defined?(:Not_Found).should.equal true
  end

end # === describe MODEL: !sub_action ===


