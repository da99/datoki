
describe :varchar do # ================================================

  it "raises RuntimeError if allow :null and :min = 0" do
    should.raise(RuntimeError) {
      Class.new {
        include Datoki
        field(:name) { varchar nil, 0, 50 }
        def create
          clean :name
        end
      }
    }.message.should.match /varchar can't be both: allow :null && :min = 0/
  end

  it "fails when varchar is less than min: varchar x, y" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 3, 255 }
        def create
          clean :title
        end
      }.create :title => '1'
    }.error[:msg].should.match /Title must be between 3 and 255 characters/i
  end

  it "fails when varchar is longer than max" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 0, 5 }
        def create
          clean :title
        end
      }.create :title => '123456'
    }.error[:msg].should.match /Title must be between 0 and 5 characters/
  end

  it "fails when varchar does not match pattern: match /../" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field :title do
          varchar
          match /\A[a-zA-Z0-9]+\z/i, "Title must be only: alphanumeric"
        end
        def create
          clean :title
        end
      }.create :title => '$! title'
    }.error[:msg].should.match /Title must be only: alphanumeric/
  end

  it "allows varchar to be nil" do
    r = Class.new {
      include Datoki
      field(:title) { varchar nil, 1, 123 }
      field(:body) { varchar nil, 1, 123 }
      def create
        clean :title, :body
      end
    }.create({:body=>'yo'})
    r.clean.has_key?(:title).should == false
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
      def create
        clean :title
      end
    }.
    create(:title => 'My Title').
    clean[:title].should.match /Custom title/
  end

  it "strips varchars by default" do
    Class.new {
      include Datoki
      field(:title) { varchar }
      def create
        clean :title
      end
    }.
    create(:title => ' my title ').
    clean[:title].should == 'my title'
  end

  it "can prevent varchar from being stripped" do
    Class.new {
      include Datoki
      field(:title) {
        varchar
        disable :strip
      }
      def create
        clean :title
      end
    }.
    create(:title => ' my title ').
    clean[:title].should == ' my title '
  end

end # === describe varchar ===
