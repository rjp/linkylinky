require 'rubygems'
require 'linkyplugin'
require 'open-uri'
require 'hpricot'

class TwitpicPlugin < PluginBase
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

a=TwitpicPlugin.new
p a.title('http://twitpic.com/ixhuc')
