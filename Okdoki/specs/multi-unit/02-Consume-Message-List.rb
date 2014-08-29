

describe "Consuming a message list:" do

  before do
    delete_all Screen_Name, Customer
  end

  it "retrieves the latest 25 messages from a consume list" do
    # === Create test data
    consumer = customer_create 'bob'
    producers = []
    msgs     = []
    3.times do |num|
      producers << customer_create "star_#{num}"
      10.times do |num|
        msgs.unshift "Hello msg #{producers.last.screen_name}: #{num}"
        Message.create producers.last.screen_name, msgs.first
      end
      Consume.create 'follow',  consumer.screen_name, producers.last.screen_name
    end

    # === test it
    list = Message.read_list 'follow', consumer
    list.size.should            == 25
    list.first.data.body.should == msgs.first
    list.last.data.body.should  == msgs[24]
  end # === it

  it "does not include messages if producer life is protected and Consumer is not allowed." do
    consumer = customer_create 'bob'
    producer_1 = customer_create 'star_1'
    producer_2 = customer_create 'star_2'

    Message.create producer_1.screen_name, 'Msg 1'
    Message.create producer_2.screen_name, 'MSG 2', :to, [producer_1.screen_name.screen_name]
    Consumer.create 'follow', consumer.screen_name, producers.first.screen_name
    Consumer.create 'follow', consumer.screen_name, producers.last.screen_name

    # === test it
    list = Message.read_list 'follow', consumer
    list.map { |m| m.data.body }.should == ['Msg 1']
  end

  it "does not retreive messages if consumer is banned by producer" do
    consumer = customer_create 'bob'

    producer_1 = customer_create "star_1"
    Message.create producer_1.screen_name, "Prod 1"

    producer_2 = customer_create "star_2"
    Message.create producer_1.screen_name, "Prod 2"

    Consume.create 'follow', consumer.screen_name, producer_1.screen_name
    Consume.create 'follow', consumer.screen_name, producer_2.screen_name
    Consume.create 'ban',    consumer.screen_name, producer_2.screen_name

    # === test it
    list = Message.read_list 'follow', consumer
    list.map { |m| m.data.body }.should == ["Prod _1"]
  end


end # === desc
