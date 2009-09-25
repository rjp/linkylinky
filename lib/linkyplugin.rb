module PluginSugar
  def def_field(*names)
    class_eval do 
      names.each do |name|
        define_method(name) do |*args| 
          case args.size
          when 0: instance_variable_get("@#{name}")
          else    instance_variable_set("@#{name}", *args)
          end
        end
      end
    end
  end
end

class Plugin
    @registered = {}
    class << self
        attr_reader :registered
        private :new
    end

    def self.define(name, &block)
        p = new
        p.instance_eval(&block)
        Plugin.registered[name] = p
    end

    def accept(uri)
        allowed = false

        unless @match_uri.nil? then
            puts "#{uri} =~ #{@match_uri}"
            if uri.match(Regexp.new(@match_uri)) then
                allowed = true
            end
        end
        unless @negative_match_uri.nil? then
            puts "#{uri} =~ #{@negative_match_uri}"
            if uri.match(Regexp.new(@negative_match_uri)) then
                allowed = false
            end
        end
        unless @filter_uri.nil? then
            puts "#{uri} =~ #{@filter_uri}"
            if uri.match(Regexp.new(@filter_uri)) then
                allowed = :filter
            end
        end

        puts "#{uri} => #{self.class} => #{allowed}"
        return allowed
    end

    def title(uri)
        return "<URI: #{uri} >"
    end

    extend PluginSugar
    def_field :author, :version
    def_field :match_host, :match_uri
    def_field :negative_match_uri
    def_field :filter_uri
end

module LinkyLinky
	def init_plugins(dir)
	    Dir.glob(dir + '/*.rb').each { |rb| load rb }
	end
end

