require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'test/unit'

require 'linkyplugin'
include LinkyLinky

Plugin.define "amazon" do
    author "rjp"
    version "0.0.1"
    match_uri '\bamazon\b(\.\w+){1,2}\/'
    priority 5

    def fetch(uri, type, size, body)
        self.fetch_all(uri, type, size, body)
    end

    def title(uri, type, size, body)
        doc = Hpricot(body)
        entry = doc.at('//title')
        title_text = 'Amazon'

        if entry then
            title_text = entry.inner_text
        end

        return title_text
    end

    # TODO implement a postfilter because this is nonsense
    # Amazon.com: Arguing with Idiots: How to Stop Small Minds and Big Government (9781416595014): Glenn Beck, Kevin Balfe: Books
    # Hot Shots: How to Refresh Your Photos: Amazon.co.uk: Kevin Meredith: Books
end

class TC_plugin_amazon < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @amazon = Plugin.registered['amazon']
    end

    def test_amazon
        assert_not_nil(@amazon)
        assert_respond_to(@amazon, 'title')
        assert_respond_to(@amazon, 'author')
        assert_respond_to(@amazon, 'match_uri')
        assert_respond_to(@amazon, 'negative_match_uri')
    end

    def test_amazon_accept
        assert_equal(true, @amazon.accept('amazon.com/photos/monkey/weasel', 'text/html'))
        assert_equal(false, @amazon.accept('notamazon.com/monkey/weasel', 'text/html'))
        assert_equal(false, @amazon.accept('amazonian.com/monkey/weasel', 'text/html'))
    end

    def test_amazon_online
        return unless ENV['LL_ONLINE']

#       Hot Shots: How to Refresh Your Photos: Amazon.co.uk: Kevin Meredith: Books
        a = @amazon.fetch('http://www.amazon.co.uk/dp/2888930277', 'text/html', 1234, '') 
        assert_not_nil(a)
        assert_not_nil(@amazon.title(*a))
        assert_equal('Hot Shots: How to Refresh Your Photos: Amazon.co.uk: Kevin Meredith: Books', @amazon.title(*a))
        puts "[#{@amazon.title(*a)}]"
    end
end
