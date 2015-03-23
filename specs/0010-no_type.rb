

describe 'No type' do

  it "requires type to be specified" do
    should.raise(RuntimeError) {
      Class.new {
        include Datoki
        field(:title) {  }
      }
    }.message.should.match /Type not specified/
  end

end # === describe 'No type' ========================================
