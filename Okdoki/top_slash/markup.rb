
title "Okdoki: Not Ready"

section(:main) {

  div.sidebar.sidebar! {

    h1.title {
      span.main "mega"
      span.sub "UNI"
    }

    div.header! {
      p do
        span.about "Multi-Life Chat & Publishing"
        br
        span "Coming later this year."
      end
      p do
        strong "~ ~ ~"
      end
    }

    applet("New_Session")
    applet("New_Customer")

    div.footer! {
      p  {
        text! "&copy;"
        text  " 2012-{{YEAR}} OKdoki.com. Some rights reserved."
      }
      p "All other copyrights belong to their respective owners."
      p {
        span "Cover Photo: "
        a("Bikes in Montreal", :href=>"http://www.dreamstime.com/bikes-in-a-row-free-stock-photos-imagefree84388")
      }

      p {
        span "Logo font: "
        a("Lenka Stabilo", :href=>"http://lenkavomelova.com/")
      }

      p {
        span "Life & Website Header font: "
        a("Circus", :href=>"http://openfontlibrary.org/en/font/circus")
      }

      p {
        span "Wood Pattern: "
        a("Alexey Usoltsev", :href=>"http://subtlepatterns.com/wood-pattern/")
      }

      p {
        span "Ravenna Pattern: "
        a("Sentel", :href=>"http://subtlepatterns.com/ravenna/")
      }

      p {
        span "Escheresque Pattern: "
        a("Ste Patten & Jan Meeus", :href=>"http://subtlepatterns.com/?s=Escheresque&submit=Search")
      }

      p {
        span "Palettes: "
        a("dvdcpd", :href=>"http://www.colourlovers.com/lover/dvdcpd")
        a("shari_foru", :href=>"http://www.colourlovers.com/palette/154398/bedouin")
      }
    }
  }

  # div.col.Why! {
    # h3 "Create Multiple Lifes"
    # div.content "
      # One account can manage different screen names
      # at the same time. Keep things separate from among
      # co-workers, friends, and family.
    # "

    # h3 "A New Feature Each Week"

    # div.content do
      # strong "This Week:"
      # span "Chat Rooms"
      # br
      # span "
        # Use a
        # different screen name (aka life)
        # in each chat room.
      # "
    # end

    # div.content do
      # strong "Next Week:"
      # span "RSS/JSON in Chat"
      # br
      # span "
        # Have RSS items
        # stream into your chat window.
      # "
    # end

  # }

}



