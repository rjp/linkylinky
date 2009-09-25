require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "newsbbc" do
    author "rjp"
    version "0.0.1"
    filter_uri 'news.bbc.co.uk'

    def postfilter(title)
# <title>BBC NEWS | World | Europe | 'Two bodies' on mafia waste ship</title> 
        return title.gsub(%r{^\s*BBC NEWS.*?\|.*?\|\s+}, '')
    end
end

class TC_plugin_newsbbc < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @newsbbc = Plugin.registered['newsbbc']
    end

    def test_newsbbc
        assert_not_nil(@newsbbc)
        assert_respond_to(@newsbbc, 'title')
        assert_respond_to(@newsbbc, 'author')
        assert_respond_to(@newsbbc, 'match_uri')
        assert_respond_to(@newsbbc, 'negative_match_uri')
    end

    def test_newsbbc_accept
        assert_equal(@newsbbc.accept('newsbbc.com/photos/cock/weasel'), false)
        assert_equal(@newsbbc.accept('newsbbc.com/cock/weasel'), false)
    end

    def test_newsbbc_filter
        assert_equal(@newsbbc.postfilter("BBC NEWS | World | Europe | 'Two bodies' on mafia waste ship"), "Europe | 'Two bodies' on mafia waste ship")
    end
end
