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
        ['title', '__X__', '', '', '[No title]']
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

def title_from_uri(uri)
    real_size = -34
    postfilter = nil

    # shortcut the fetching if we have a plugin that will handle this
    Plugin.registered.each { |name, plugin|
        t = nil
        case plugin.accept(uri)
            when true
                return plugin.title(uri), true
            when :filter
                puts "POSTFILTER FOR #{name}"
                postfilter = Proc.new { |i| plugin.postfilter(i) }
        end
    }
puts "no plugin claimed [#{uri}]"

    curl = Curl::Easy.new
    curl.url = uri
    curl.headers['Range'] = 'bytes=0-16383'
    curl.headers['User-Agent'] = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)'
    curl.follow_location = true
    puts "curling"
    begin
        curl.perform
    rescue => e
        puts e
        exit
    end
    puts "curled"
    body = curl.body_str
    curl.header_str.split(/\r\n/).grep(/^Content-Range/).each { |x|
        y = x.scan(%r{^.*bytes (\d+)-(\d+)(?:/(\d+))?})
        if y[0] and y[0][2] then
            real_size = y[0][2]
        end
    }

    puts "got #{body.size} bytes"

    # some formats need the end of the file as well
    # small hardcoded list will do for now
    need_end = ['audio/mpeg'].grep curl.content_type
    if need_end.size > 0 then
	    curl.headers['Range'] = 'bytes=-16384'
	    curl.follow_location = true
	    curl.perform
        body = body + curl.body_str
    end

    pre_filter = title_from_text(body)
    puts "pre title = #{pre_filter}"
    unless postfilter.nil? then
        pre_filter = postfilter.call(pre_filter)
        puts "updating title with postfilter => #{pre_filter}"
    end

    return pre_filter.strip
end

def title_from_text(text)
    metadata = {}
    # write the body to a tempfile
    Tempfile.open('lnkylnky', '/tmp') { |t|
        t.print text
        t.flush
        metadata = title_from_file(t.path)
        t.close!
    }
    return metadata
end

def title_from_file(file)
    m = Extractor.extract(file)
    m['_meta_title'] = make_nice_title(m)
    return m['_meta_title']
end
