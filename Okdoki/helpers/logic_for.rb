
Cache_For_Logic_For = {}

helpers do

  def partials_list_for sub_path
    Cache_For_Logic_For[sub_path] ||= begin
                                        File.read("./Server/#{sub_path}/order.txt")
                                        .split
                                        .map(&:strip)
                                        .reject { |s| s.empty? }
                                      end
  end

  def logic_for sub_path
    app  = self
    path = "./Server/#{sub_path}"
    name = sub_path.gsub('/', '__')
    partials = partials_list_for(sub_path)

   partials.each { |p_name|
      p_klass_name = "#{name}__#{p_name}"
      p_klass = begin
                  Object.const_get p_klass_name
                rescue NameError => e
                  require "#{path}/#{p_name}/logic"
                  Object.const_get p_klass_name
                end
      p_klass.new.run app
    }
  end


end # === helpers
