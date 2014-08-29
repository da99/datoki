
require './Server/MODEL/model'

# ============ CREATE ===============================================

post "/MODEL" do

  begin
    MODEL.create(params)
  rescue MODEL::Invalid =>e
    json false, e.msg
  end

end # === post /MODEL

# ============ READ =================================================

get "/MODEL/:id" do

  begin
    MODEL.read(params)
  rescue MODEL::Not_Found =>e
    json false, e.msg
  end

end # === get /MODEL/:id


# ============ UPDATE ===============================================



# ============ TRASH ================================================



# ============ UNTRASH ==============================================




