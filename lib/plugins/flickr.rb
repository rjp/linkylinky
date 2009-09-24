require 'rubygems'
require 'linkyplugin'
require 'open-uri'
require 'hpricot'

class FlickrPlugin < PluginBase
    author "rjp"
    version "0.0.1"
    match_uri 'flickr.com/photos/(.*?)/(.+)'

    def title(uri)
        uri =~ Regexp.new(FlickrPlugin.match_uri)
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

a=FlickrPlugin.new
p a.title('http://www.flickr.com/photos/8279638@N05/3877512686/')
p a.title('http://www.flickr.com/photos/eric_parey/3877173831/')
