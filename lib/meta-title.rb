require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'
require 'curb'

require 'linkyplugin'
include LinkyLinky

# OpenURI doesn't allow http->https redirection by default
def OpenURI.redirectable?(uri1, uri2) # :nodoc:
    # This test is intended to forbid a redirection from http://... to
    # file:///etc/passwd.
    # However this is ad hoc.  It should be extensible/configurable.
    uri1.scheme.downcase == uri2.scheme.downcase ||
    (/\A(?:http|ftp|https)\z/i =~ uri1.scheme && /\A(?:http|ftp|https)\z/i =~
uri2.scheme)
end

# TODO make this not quite so hardcoded
puts "loading plugins"
init_plugins('/home/rjp/git/linkylinky/lib/plugins')
puts "Loaded: " + Plugin.registered.keys.join(', ')

# key, substitution formatting, prefix string, postfix string
$format_strings = {
    'image' => [
        ['camera model', nil, '', ', '],
        ['focal length', nil, '', ', '],
        ['exposure', nil, '', ', ']
    ],
    'audio' => [
        ['title', '"__X__"', '', '', '[Unknown]'],
        ['artist', nil, ' by ', ''], #, '[Unknown]'],
        ['album', '"__X__"', ' off ', '', '[Unknown]'],
        ['year', nil, ', ', '']
    ],
    'text' => [
        ['title', '__X__', '', '', '[No.title]']
    ]
}

# key, formatter, prefix, postfix
def format_list(m)
    m['mimetype'] ||= 'text/html'
    m.keys.each { |i|
        m[i] = m[i].to_a.uniq.first # because extractor is annoying
    }
    mimetype = m['mimetype'].downcase
    majortype = mimetype.gsub(%r{^(.*?)/.*$},'\1') # major type
    # rubbish default title but eh
    def_title = "[" + mimetype + (m['size'] ? ', ' + m['size'] : '') + "]"

    f = $format_strings[majortype]
    if f.nil? then
        return def_title
    end

    title = ''
    added = 0
    previous = ''
    f.each { |k, fm, pr, po, default|
        if m[k] then
            if added == 1 then
                title = title + previous
            end
            added = 1
            x = m[k]
        else
            x = default
        end
        y = x
        unless x.nil? then
	        unless fm.nil? then y = fm.gsub('__X__', x); end
	        title = title + pr + y
        end
        previous = po
    }

    return title.length > 0 ? title : def_title
end

def make_nice_title(m)
    m['mimetype'] ||= 'text/html'

    m.keys.each { |i|
        m[i] = m[i].to_a.uniq.first
    }

    return format_list(m)
end

def title(uri)
    x=''
    open(uri, :progress_proc => lambda{|x|p x}) { |fh|
        x = fh.read(12)
        break
    }
    p x
end

	def fetch(uri)
        content_type = nil

	    curl = Curl::Easy.new
	    curl.url = uri
	    curl.headers['Range'] = 'bytes=0-16383'
	    curl.headers['User-Agent'] = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)'
	    curl.follow_location = true
	    curl.perform
	    body = curl.body_str

	# try to grab the real size of the content from the headers
	    real_size = nil
	    curl.header_str.split(/\r\n/).grep(/^Content-Range/).each { |x|
            p "CR #{x}"
	        y = x.scan(%r{^.*bytes (\d+)-(\d+)(?:/(\d+))?})
	        if y[0] and y[0][2] then
	            real_size = y[0][2]
	        end
	    }

	    curl.header_str.split(/\r\n/).grep(/^Content-Length/).each { |x|
	        y = x.scan(%r{^.*: (\d+)})
            p "CL #{x} #{y[0].inspect}"
	        if y[0] then
	            real_size = y[0]
	        end
	    }

    content_type = curl.content_type

	# always fetch the last 16k as well
    unless ['image/png'].index(content_type) then
	    curl.headers['Range'] = 'bytes=-16384'
	    curl.follow_location = true
	    curl.perform
	    body = body + curl.body_str
    end

	    return content_type, real_size, body
	end

def title_from_uri(uri)
    real_size = -34
    postfilter = nil

    # get initial triplet of information
    type, size, body = fetch(uri)
    puts "#{type} #{size} #{body.length}"

    current = Plugin.registered['default']

    # pick the highest priority plugin that'll handle this
    Plugin.registered.each { |name, plugin|
#        puts "testing #{uri} against #{name}"
        if plugin.accept(uri, type) then
            if plugin.priority > current.priority then
                current = plugin
            end
        end
    }

    new_uri, type, size, body = current.fetch(uri, type, size, body)
    pre_title = current.title(new_uri, type, size, body)
    title = current.postfilter(pre_title.strip)

    return title.strip, current.suppress_domain
end
