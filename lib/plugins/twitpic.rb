require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "twitpic" do
    author "rjp"
    version "0.0.1"
    match_uri 'twitpic.com/.*'
    negative_match_uri 'twitpic.com/.*\.do$'

    def title(uri)
        realname = "<x#{$1}>"
        desc = 'x'

        doc = Hpricot(open(uri))

        name = doc.at('div#view-photo-user > div#photo-info > div > a')
        realname = name.inner_text

        desc = doc.at('img#photo-display')['alt']

        return "(twitpic) #{realname}: #{desc}"
    end
end

class TC_plugin_twitpic < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @twitpic = Plugin.registered['twitpic']
    end

    def test_twitpic
        assert_not_nil(@twitpic)
        assert_respond_to(@twitpic, 'title')
        assert_respond_to(@twitpic, 'author')
        assert_respond_to(@twitpic, 'match_uri')
        assert_respond_to(@twitpic, 'negative_match_uri')
    end

    def test_twitpic_accept
        assert_equal(@twitpic.accept('twitpic.com/zippy'), true)
        assert_equal(@twitpic.accept('twitpic.com/api.do'), false)
    end

    def test_twitpic_online
        return unless ENV['LL_ONLINE']

        assert_not_nil(@twitpic.title('http://www.twitpic.com/ixhuc'))
    end
end
