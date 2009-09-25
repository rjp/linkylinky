require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "flickr" do
    author "rjp"
    version "0.0.1"
    match_uri 'flickr.com/photos/(.*?)/(.+)'

    def title(uri)
        uri =~ Regexp.new(@match_uri)
        realname = "<x#{$1}>"
        doc = Hpricot(open(uri))

        entry = doc.at('meta[@name="title"]')
        title = entry['content']

        doc.search("b[@property]").each {|i|
            if i['property'] == 'foaf:name' then
                realname = i.inner_text
            end
        }

        return "(flickr) #{realname}: #{title}"
    end
end

class TC_plugin_flickr < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @flickr = Plugin.registered['flickr']
    end

    def test_flickr
        assert_not_nil(@flickr)
        assert_respond_to(@flickr, 'title')
        assert_respond_to(@flickr, 'author')
        assert_respond_to(@flickr, 'match_uri')
        assert_respond_to(@flickr, 'negative_match_uri')
    end

    def test_flickr_accept
        assert_equal(@flickr.accept('flickr.com/photos/cock/weasel'), 1)
        assert_equal(@flickr.accept('flickr.com/cock/weasel'), 0)
    end

    def test_flickr_online
        return unless ENV['LL_ONLINE']

        assert_not_nil(@flickr.title('http://www.flickr.com/photos/8279638@N05/3877512686/'))
        assert_not_nil(@flickr.title('http://www.flickr.com/photos/eric_parey/3877173831/'))
    end
end
