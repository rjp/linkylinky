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

    def title(uri)
    puts "isn't it?"
        doc = Hpricot(open(uri))
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
        assert_equal(@twitter.accept('twitter.com/rjp/status/1234'), 1)
        assert_equal(@twitter.accept('http://twitter.com/rjp/status/1234'), 1)
        assert_equal(@twitter.accept('twitter.com/cock/weasel'), 0)
    end

    def test_twitter_online
        return unless ENV['LL_ONLINE']

        assert_not_nil(@twitter.title('http://twitter.com/crickybo/status/4126965179'))
        assert_not_nil(@twitter.title('http://twitter.com/otama23/status/4337424688'))
    end
end
