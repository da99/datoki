

describe "on :create" do

  it "after all fields have been cleaned" do
    Class.new {

      include Datoki

      on :create, def collect_values
        clean_data[:values] = clean_data.values.join ', '
      end

      field(:title) { varchar }

      field(:body) { varchar }

    }.
    create(:title=>'my title', :body=>'my body').
    clean_data[:values].should == 'my title, my body'
  end

  it "runs after validation for a field" do
    Class.new {
      include Datoki
      field(:body) {
        on :create, def add_stuff
          clean_data[:body] << ' with new stuff'
        end

        varchar
      }
    }.
    create(:body=>'the body').
    clean_data[:body].should == 'the body with new stuff'
  end

end # === describe on :create


