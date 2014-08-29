
require 'Bacon_Colored'
require './Server/Customer/specs/helpers'
require 'pry'

def days_ago_in_sql days
  Sequel.lit(Okdoki::Model::PG::UTC_NOW_RAW + " - interval '#{days * 24} hours'")
end

def customer
  Customer.new(:data)
end

def less_than x
  lambda { |o| o < x }
end

def within_secs x
  lambda { |o|
    o.class.should.equal Time
    !!o && (Time.now.utc.to_i - o.to_i).abs < x
  }
end

def new_body
  @i ||= 0
  "text #{@i += 1}"
end

def should_args action, *args
  case action
  when :zero, 0
    [ args.shift, [], :==, [0] ]
  when :one, 1
    [ args.shift, [], :==, [1] ]
  when Proc
    [ args.shift, [], nil, [action] ]
  else
    expect = args.shift
    actual = args.shift
    [ actual, [], action, args.unshift(expect) ]
  end
end

def assert *args
  make_should *should_args(*args)
end

def assert_not old_args
  args = should_args(*old_args)
  args[1].push :not
  make_should *args
end

def make_should o, bes_nots, meth, args
  s = Should.new(o)
  (bes_nots || []).each { |m|
    s = s.send(m)
  }

  if meth
    s.be.send(meth, *args)
  else
    s.be(*args)
  end
end














































