require 'test/unit'

require 'linkyplugin'
include LinkyLinky

# empty plugin 
Plugin.define "default" do
    author "rjp"
    version "0.0.1"
    priority -1
end

class TC_plugin_default < Test::Unit::TestCase
    def setup
        if Plugin.registered.keys.size == 0 then
            puts "loading plugins"
            init_plugins('/home/rjp/git/linkylinky/lib/plugins')
            assert_not_nil(Plugin.registered.keys)
        end
        @default = Plugin.registered['default']
    end

    def test_default
        assert_not_nil(@default)
        assert_respond_to(@default, 'title')
        assert_respond_to(@default, 'author')
        assert_respond_to(@default, 'priority')
    end

    def test_default_accept
        assert_equal(false, @default.accept('default.com/photos/weasel/stick', 'text/html'))
    end

    def test_default_filter
        assert_equal("xyz_plots", @default.postfilter("xyz_plots"))
    end
end
