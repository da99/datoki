
describe "Consuming an app:" do

  it "returns a record with :allowed? = FALSE if person is not allowed to view SN"
  it "returns a record with :allowed? = FALSE if person is not allowed to view Customer of SN"

  it "returns a record with :applet_consume_allowed? = FALSE if person is not allowed to view any of the applets"
  it "returns a record with :applet_consume_allowed? = FALSE if Customer/Owner is not allowed to view any of the applets"
  it "returns a record with :applet_consume_allowed? = FALSE if SN/Owner is not allowed to view any of the applets"

  it "returns a record with :banned_editor_consume?  = TRUE if consume of banned Editor exists"

end # === desc
