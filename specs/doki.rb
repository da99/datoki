
describe Doki do

  it "runs" do
    c = Class.new {
      include Doki
      field :name do
        string 3
      end
    }
    record = c.new
    should.raise(Doki::Invalid) {
      record.new_data :name=>'1234'
    }.message.should.match /"Name" is too long./
  end

end # === describe doki ===
