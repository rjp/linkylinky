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
    # load our plugins from a specified directory
	def init_plugins(dir)
	    Dir.glob(dir + '/*.rb').each { |rb| load rb }
	end

    # parse out a title from some text
	def title_from_text(type, size, text)
	    metadata = {}
        # Extractor::extract only works on real files
	    # write the text to a tempfile so it can be extracted
	    Tempfile.open('lnkylnky', '/tmp') { |t|
	        t.print text
	        t.flush
	        metadata = title_from_file(t.path)
	        t.close!
	    }
	    return metadata
	end

    # extract and format metadata from a file
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

    # default accept routine
    # plugin will accept a URI if @match_uri or @filter_uri matches and @negative_match_uri doesn't
    def accept(uri, type)
        allowed = false

        unless @match_uri.nil? then
            if uri.match(Regexp.new(@match_uri)) then
                allowed = true
            end
        end
        unless @negative_match_uri.nil? then
            if uri.match(Regexp.new(@negative_match_uri)) then
                allowed = false
            end
        end
        unless @filter_uri.nil? then
            if uri.match(Regexp.new(@filter_uri)) then
                allowed = true
            end
        end

        return allowed
    end

    # abstract title method just returns the default formatted metadata
    def title(uri, type, size, body)
        return title_from_text(type, size, body)
    end

    # abstract postfilter method does nothing
    def postfilter(title)
        return title
    end

    # abstract fetch method returns the results of the pre-fetch
    def fetch(uri, type, size, body)
        return uri, type, size, body
    end

    # helper fetch_all method for plugins like twitter/flickr/twitpic
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

