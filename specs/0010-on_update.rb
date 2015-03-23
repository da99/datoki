

describe "on :update" do

  it "runs after data has been cleaned" do
    r = Class.new {
      include Datoki
      on :update, def do_something
        clean_data[:vals] = clean_data.values.join ' -- '
      end

      field(:title) { varchar }
      field(:body) { varchar }
    }.new(:title=>'old title')
    r.update title: ' new title ', :body=>'  new body  '
    r.clean_data[:vals].should == 'new title -- new body'
  end

end # === describe on :update

