require 'rubygems'
require 'linkyplugin'
require 'open-uri'
require 'hpricot'

class TwitterPlugin < PluginBase
    author "rjp"
    version "0.0.1"
    match_uri 'twitter.com/(.*?)/status/(.+)'

    def title(uri)
        doc = Hpricot(open(uri))
        entry = doc.at('span.entry-content').inner_text
        realname = doc.at('div.full-name').inner_text

        return "(twitter) #{realname}: #{entry}"
    end
end

a=TwitterPlugin.new
p a.title('http://twitter.com/crickybo/status/4126965179')
p a.title('http://twitter.com/otama23/status/4337424688')
