
# =====================================================
# Read
# =====================================================

get "/" do
  if logged_in?
    html 'Customer/lifes', {
      :intro        => "My Account...",
      :default_sn   => user.screen_names.first.to_public,
      :screen_names => user.screen_names.map(&:to_public),
      :sn_all       => user.screen_names.map(&:screen_name).join(', '),
      :is_owner     => logged_in?
    }
  else
    html 'Okdoki/top_slash', {
      title: 'OkDoki.com',
      YEAR: Time.now.year
    }
  end
end # === get /
