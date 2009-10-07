require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "flickr_static" do
    author "rjp"
    version "0.0.1"
    match_uri 'static.flickr.com/(.*)/(.+?)_(.+?)(_.*|\..*)$'
    priority 5
    suppress_domain true

    def fetch(uri, type, size, body)
        self.fetch_all(uri, type, size, body)
    end

    def title(uri, type, size, body)
        uri =~ Regexp.new(@match_uri)
        photo_id = $2
        hash = $3
        realname = "#{$2}_#{$3}_#{$4}"
        body = open("http://flickr.com/photo.gne?id=#{photo_id}")

        ### from here, it's identical to the flickr plugin ###
        doc = Hpricot(body)
        entry = doc.at('meta[@name="title"]')

        if entry then
            title = entry['content']
        else # did we get bounced to a login page?
            if doc.at('title').inner_text =~ /Sign in/ then
                return "(flickr) #{realname}: Protected Photo, sorry"
            end
        end

        doc.search("b[@property]").each {|i|
            if i['property'] == 'foaf:name' then
                realname = i.inner_text
            end
        }

        return "(flickr) #{realname}: #{title}"
    end
end

class TC_plugin_flickr_static < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @flickr_static = Plugin.registered['flickr_static']
    end

    def test_flickr_static
        assert_not_nil(@flickr_static)
        assert_respond_to(@flickr_static, 'title')
        assert_respond_to(@flickr_static, 'author')
        assert_respond_to(@flickr_static, 'match_uri')
        assert_respond_to(@flickr_static, 'negative_match_uri')
    end

    def test_flickr_static_accept
        assert_equal(true, @flickr_static.accept('flickr_static.com/photos/monkey/weasel', 'text/html'))
        assert_equal(false, @flickr_static.accept('flickr_static.com/monkey/weasel', 'text/html'))
    end

    def test_flickr_static_online
        return unless ENV['LL_ONLINE']

        a = @flickr_static.fetch('http://www.flickr_static.com/photos/8279638@N05/3877512686/', 'text/html', 1234, '') 
        assert_not_nil(a)
        assert_not_nil(@flickr_static.title(*a))

        a = @flickr_static.fetch('http://www.flickr_static.com/photos/eric_parey/3877173831/', 'text/html', 1234, '')
        assert_not_nil(a)
        assert_not_nil(@flickr_static.title(*a))
    end
end
