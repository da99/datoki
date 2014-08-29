
require "addressable/uri"
require "escape_utils"
require "htmlentities"
require "uri"

# =====================================================================
# if respond_to? :helpers, true
  # helpers do

    # def params
      # @clean_params ||= begin
                          # dirty = super
                          # return dirty if dirty.empty?

                          # o = {}
                          # super.keys.each do |k|
                            # o[Okdoki::Escape_All.escape(k.to_s).to_sym] doki= Okdoki::Escape_All.escape(dirty[k])
                          # end

                          # o
                        # end
    # end

  # end # === end helpers
# end
# =====================================================================


module Okdoki
  module Escape_All

    Underscore_URI_KEY = /_(uri|url|href)$/
    URI_KEY            = /^(uri|url|href)$/

    Coder = HTMLEntities.new(:xhtml1)

    ENCODING_OPTIONS_CLEAN_UTF8 = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => ''         # Use a blank for those replacements
      # :newline => :universal
      # :universal_newline => true       # Always break lines with \n, not \r\n
    }

    opts = Regexp::FIXEDENCODING | Regexp::IGNORECASE

    # tabs, etc.
    Control = Regexp.new("[[:cntrl:]]".force_encoding('utf-8'), opts)   # unicode whitespaces, like 160 codepoint
    # From:
    # http://www.rubyinside.com/the-split-is-not-enough-whitespace-shenigans-for-rubyists-5980.html
    White_Space =  Regexp.new("[[:space:]]".force_encoding('utf-8'), opts)


    def new_regexp str
      Regexp.new(clean_utf8(str), Regexp::FIXEDENCODING | Regexp::IGNORECASE)
    end

    class << self # ===============================================================================

      # From:
      # http://stackoverflow.com/questions/1268289/how-to-get-rid-of-non-ascii-characters-in-ruby
      #
      # Test:
      # [160, 160,64, 116, 119, 101, 108, 108, 121, 109, 101, 160, 102, 105, 108, 109].
      #   inject('', :<<)
      #
      def clean_utf8 s
        s.
          encode(Encoding.find('utf-8'), ENCODING_OPTIONS_CLEAN_UTF8).
          gsub(Escape_All::Control,    "\n").
          gsub(Escape_All::White_Space, " ")
      end

      def un_e raw
        EscapeUtils.unescape_html clean_utf8(raw)
      end

      def e_uri str
        uri = Addressable::URI.parse(str)
        if ["http","https","ftp"].include?(uri.scheme) || uri.path.index('/') == 0
          str
        else
          nil
        end
      rescue Addressable::URI::InvalidURIError
        nil
      end

      def is_uri_key raw_key
        return false unless raw_key
        k = raw_key.to_s.strip.downcase
        k && (k[Underscore_URI_KEY] || k[URI_KEY])
      end

      def _e o, key = nil
        # EscapeUtils.escape_html(un_e o)
        if key && key.to_s['pass_']
          o
        elsif is_uri_key(key)
          clean = e_uri(_e(o))
        else
          Coder.encode(un_e(o), :named, :hexadecimal)
        end
      end

      def escape o, key = nil
        return(o.map { |v| Escape_All.escape(v) }) if o.kind_of? Array

        if o.kind_of? Hash
          new_o = {}

          o.each { |k, v| new_o[Escape_All.escape(k)] = Escape_All.escape(v, k) }

          return new_o
        end

        return Escape_All._e(o, key) if o.is_a?(String)

        if o.is_a?(Symbol)
          return Escape_All._e(o.to_s).to_sym
        end

        if o == true || o == false || o.kind_of?(Numeric)
          return o
        end

        raise "Unknown type: #{o.class}"
      end # === def

    end # === class self ==========================================================================

  end # === mod Escape_All ===
end # === module Ok ===



