

# =====================================================
# Use it as middleware, set-up Sinatra routes
# =====================================================

get "/log-out" do
  log_out
  redirect to("/"), 307 # --- temp redirect
end

post '/sign-in' do

  return json(false, "Screen name is required.") if (params[:screen_name] || "").strip.empty?

  return json(false, "Pass phrase is required.") if (params[:pass_word] || "").strip.empty?

  begin
    c = Customer.read_by_screen_name_and_pass_word(params[:screen_name], params[:pass_word], request.env['REMOTE_ADDR'])
    sign_in c
    json(true, "You are now logged in to: #{request.host}", :location=>c.to_href)

  rescue Screen_Name::Not_Found => e
    json(false, e.msg)

  rescue Customer::Invalid => e
    json(false, e.msg)

  rescue Customer::Too_Many_Bad_Logins => e
    json(false, e.msg)

  end

end # === post


if ENV['IS_DEV']
  def add_padding k
    padding = 30
    size = (padding - k.to_s.size)
    size = 1 if size < 1
    " " * size
  end

  def inspect_line k, v
    "#{k.inspect}:#{add_padding k}#{v.inspect}\n"
  end

  get "/test/session" do
    pass if env['HTTP_X_REAL_IP'] != '127.0.0.1'

    a = "Session: \n"
    session.each { |k, v| a  << inspect_line(k, v) }

    a << "\n\nHeaders:\n"
    env.each { |k, v| a  << inspect_line(k, v) }

    content_type :text
    a
  end
end

# =====================================================



