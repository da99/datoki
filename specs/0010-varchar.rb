
describe :varchar do # ================================================

  it "requires field by default" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar }
      }.create({})
    }.message.should.match /Title is required/i
  end

  it "raises RuntimeError if allow :null and :min = 0" do
    should.raise(RuntimeError) {
      Class.new {
        include Datoki
        field(:name) { varchar nil, 0, 50 }
      }
    }.message.should.match /varchar can't be both: allow :null && :min = 0/
  end

  it "fails when varchar is less than min: varchar x, y" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 3, 255 }
      }.create :title => '1'
    }.message.should.match /Title must be between 3 and 255 characters/i
  end

  it "fails when varchar is longer than max" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 0, 5 }
      }.create :title => '123456'
    }.message.should.match /Title must be between 0 and 5 characters/
  end

  it "fails when varchar does not match pattern: match /../" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title do
          varchar
          match /\A[a-zA-Z0-9]+\z/i, "Title must be only: alphanumeric"
        end
      }.create :title => '$! title'
    }.message.should.match /Title must be only: alphanumeric/
  end

  it "allows varchar to be nil" do
    r = Class.new {
      include Datoki
      field(:title) {
        varchar nil, 1, 123
      }
    }.create()
    r.clean_data[:title].should == nil
  end

  it "sets field to return value of :set_to" do
    Class.new {
      include Datoki
      field(:title) {
        varchar
        set_to :custom_error
        def custom_error
          'Custom title'
        end
      }
    }.
    create(:title => 'My Title').
    clean_data[:title].should.match /Custom title/
  end

  it "strips varchars by default" do
    Class.new {
      include Datoki
      field(:title) { varchar }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == 'my title'
  end

  it "can prevent varchar from being stripped" do
    Class.new {
      include Datoki
      field(:title) {
        varchar
        disable :strip
      }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == ' my title '
  end

end # === describe varchar ===
