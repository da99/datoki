
require "./Server/Okdoki/Escape_All"
require "mustache"

FILE_STAMP = Time.now.to_i

helpers do

  def html view_name, o
    view_name_underscore = view_name.gsub '/', '__'
    Mustache.raise_on_context_miss = true
    file = "./Public/temp/#{view_name_underscore}__markup.html"
    Fake_Mustache::CACHE[file] ||= File.read(file)

    # --- add has_? helpers
    o.keys.each { |k|
      if o[k].is_a? Enumerable
        o[:"has_#{k}"] = o[k].empty? ? '' : "has_#{k}"
      end
    }

    o[:_csrf]                 = csrf_token
    o[:file_stamp]            = FILE_STAMP
    o[:logged_in?]            = logged_in?
    o[:view_name]             = view_name
    o[:is_customer_lifes]     = view_name == 'Customer/lifes'
    o[:my_other_screen_names] = begin
                                  if logged_in?
                                    list = user.screen_names.map(&:to_public)
                                    if view_name == 'Screen_Name/me'
                                      sn = Screen_Name.canonize(params[:screen_name])
                                      list.reject { |o|
                                        o[:screen_name] == sn
                                      }
                                    else
                                      list
                                    end
                                  else
                                    []
                                  end
                                end

    Mustache.render(Fake_Mustache::CACHE[file], o)
  end

end # === helpers

class Mustache
  class Context
    def escapeHTML str
      Okdoki::Escape_All.escape str
    end
  end
end # === class Mustache

class Fake_Mustache

  CACHE = {}

  def escapeHTML var
    Okdoki::Escape_All.escape(var.to_s)
  end

  def initialize raw_file, data
    file       = "Public/#{raw_file}/markup.mustache.rb"
    @data      = data
    @file_name = file
    @file      = (self.class::CACHE[file] ||= File.read(file))
  end

  def dup
    @data.dup
  end

  def [] raw_key
    sym = raw_key.to_sym
    s   = raw_key.to_s

    val = @data[sym] || @data[s]

    if !val && !@data.has_key?(sym) && !@data.has_key?(s)
      raise "Missing key for mustache: #{raw_key.inspect}"
    end

    val
  end

  def render
    ctx = self
    instance_eval @file, @file_name, 1
  end

end # === class

