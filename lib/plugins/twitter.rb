require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "twitter" do
    author "rjp"
    version "0.0.1"
    match_uri 'twitter.com/(.*?)/status(es)?/(.+)'
    priority 5

    def fetch(uri, type, size, body)
        return self.fetch_all(uri, type, size, body)
    end

    def title(uri, type, size, body)
        doc = Hpricot(body)
        el_entry = doc.at('span.entry-content') #.inner_text
        entry = el_entry.inner_text
        realname = ''
        el_name = doc.at('div.full-name') #.inner_text
        if el_name.nil? then
            el_name = doc.at('div > a.screen-name')
            realname = "@#{el_name.inner_text}"
        else
            realname = el_name.inner_text
        end

        return "(twitter) #{realname}: #{entry}"
    end
end

class TC_plugin_twitter < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @twitter = Plugin.registered['twitter']
    end

    def test_twitter
        assert_not_nil(@twitter)
        assert_respond_to(@twitter, 'title')
        assert_respond_to(@twitter, 'author')
        assert_respond_to(@twitter, 'match_uri')
        assert_respond_to(@twitter, 'negative_match_uri')
    end

    def test_twitter_accept
        assert_equal(true, @twitter.accept('twitter.com/rjp/status/1234', 'text/html'))
        assert_equal(true, @twitter.accept('http://twitter.com/rjp/statuses/1234', 'text/html'))
# this plugin currently doesn't handle links to user timelines
        assert_equal(false, @twitter.accept('twitter.com/weasel', 'text/html'))
    end

    def test_twitter_online
        return unless ENV['LL_ONLINE']

        [
            'http://twitter.com/otama23/status/4337424688',
            'http://twitter.com/crickybo/status/4126965179'
        ].each { |uri|
	        a = @twitter.fetch(uri, 'text/html', 1234, '') 
	        assert_not_nil(a)
	        assert_not_nil(@twitter.title(*a))
        }
    end
end
