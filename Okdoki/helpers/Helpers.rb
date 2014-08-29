
module Okdoki

  module Helpers

    def add_leading_zero n
      (n = '0' + n;) if (n < 10)
      n
    end

    def date d
      m   = add_leading_zero(d.getUTCMonth() + 1);
      day = add_leading_zero(d.getUTCDate());
      d.getUTCFullYear() + '-' + m + '-' + day;
    end # === def

    def add_s v
      (v > 1 ? 's' : '')
    end

    def human_durs durs
      msg = []
      d = durs.day
      h = durs.hour
      m = durs.minute
      v = null

      if (d === 1 && h === 23 && m > 45)
        d = 2
        h = 0
        m = 0
      end

      v = d
      if (v > 0)
        msg.push( v + " day" + add_s(v) )
      end

      v = h
      if (v > 0)
        msg.push(v + " hr" + add_s(v))
      end

      v = m
      if (v > 0)
        msg.push(v + " min" + add_s(v))
      end

      msg.join(', ')
    end # === def human_durs


  end # === Miscel

end # === module Okdoki
