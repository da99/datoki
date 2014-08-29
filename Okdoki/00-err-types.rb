
require "./tests/helpers"
require "./Server/Okdoki/model"

class My_Model
  include Okdoki::Model
end

describe "Exceptions:" do

  it "defines an Invalid exception" do
    My_Model::Invalid.superclass.should == Okdoki::Invalid
  end

  it "defines an Not_Found exception" do
    My_Model::Not_Found.superclass.should == Okdoki::Not_Found
  end

end # === describe Exceptions: ===

