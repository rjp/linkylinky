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

module LinkyLinky
	def init_plugins(dir)
	    Dir.glob(dir + '/*.rb').each { |rb| load rb }
	end

	def title_from_text(type, size, text)
	    metadata = {}
	    # write the body to a tempfile
	    Tempfile.open('lnkylnky', '/tmp') { |t|
	        t.print text
	        t.flush
	        metadata = title_from_file(t.path)
	        t.close!
	    }
	    return metadata
	end

	def title_from_file(file)
	    m = Extractor.extract(file)
	    m['_meta_title'] = make_nice_title(m)
	    return m['_meta_title']
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
        p.instance_variable_set("@name", name)
        Plugin.registered[name] = p
    end

    def accept(uri, type)
        allowed = false

        unless @match_uri.nil? then
#        puts "#{uri} =~ #{@match_uri}"
            if uri.match(Regexp.new(@match_uri)) then
                allowed = true
            end
        end
        unless @negative_match_uri.nil? then
#            puts "#{uri} =~ #{@negative_match_uri}"
            if uri.match(Regexp.new(@negative_match_uri)) then
                allowed = false
            end
        end
        unless @filter_uri.nil? then
#            puts "#{uri} =~ #{@filter_uri}"
            if uri.match(Regexp.new(@filter_uri)) then
                allowed = true
            end
        end

        return allowed
    end

    def title(uri, type, size, body)
        return title_from_text(type, size, body)
    end

    def postfilter(title)
        return title
    end

    def fetch(uri, type, size, body)
        return uri, type, size, body
    end

    def fetch_all(uri, type, size, body)
        io = open(uri)
        if io.status[0] == '200' then
            doc = io.read
            return uri, 'text/html', doc.length, doc
        end
        raise
    end

    def suppress_domain
        return false
    end

    extend LinkyLinky
    extend PluginSugar
    def_field :author, :version
    def_field :match_host, :match_uri
    def_field :negative_match_uri
    def_field :filter_uri, :suppress_domain
    def_field :fetcher, :priority
end

