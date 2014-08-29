require 'multi_json'

# start_server
class C
  include Server::Test
end

client = CLIENT = C.new

def GET *args
  CLIENT.GET *args
end

def POST *args
  CLIENT.POST *args
end

def _csrf
  CLIENT._csrf
end

describe "/" do

  it "returns a 200" do
    GET('/').code.to_i.should == 200
  end

  it "includes a _csrf value" do
    (GET('/')/ "#CSRF").size.should == 1
  end

end # === describe it runs ===


describe "POST /user" do

  it "raises an error if no _csrf token passed" do
    lambda {
      r = POST( "/user", {'screen_name'=>'ted1', 'pass_word'=>'this is mey  passw'}, 'X-CSRF-Token' => nil)
    }.should.raise(Mechanize::ResponseCodeError).
      response_code.to_i.should == 500
  end

  it "tells user confirm_pass_phrase is required." do
    r = POST( "/user", 'screen_name'=>'ted1', 'pass_word'=>'this is mey  passw')
    reply = MultiJson.load(r.body)
    reply['success'].should == false
    reply['msg'].should == "Pass phrase confirmation is required."
  end

end # === describe

