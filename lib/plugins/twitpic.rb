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
    priority 5

    def fetch(uri, type, size, body)
        return self.fetch_all(uri, type, size, body)
    end

    def title(uri, type, size, body)
        realname = "<x#{$1}>"
        desc = 'x'

        doc = Hpricot(body)

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
        assert_equal(true, @twitpic.accept('twitpic.com/zippy', 'text/html'))
        assert_equal(false, @twitpic.accept('twitpic.com/api.do', 'text/html'))
    end

    def test_twitpic_online
        return unless ENV['LL_ONLINE']

        a = @twitpic.fetch('http://www.twitpic.com/ixhuc', 'text/html', 1234, '')
        assert_not_nil(a)
        assert_not_nil(@twitpic.title(*a))
    end
end
