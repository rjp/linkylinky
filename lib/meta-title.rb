require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'
require 'curb'

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
        ['title', '"__X__"', '', '', '[No title]']
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
    def_title = "[#{mimetype}" << (m['size'] ? ', '<<m['size'] : '') << ']'

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

    curl = Curl::Easy.new
    curl.url = uri
    curl.headers['Range'] = 'bytes=0-16383'
    curl.follow_location = true
    curl.perform
    body = curl.body_str
    curl.header_str.split(/\r\n/).grep(/^Content-Range/).each { |x|
        y = x.scan(%r{^.*bytes (\d+)-(\d+)(?:/(\d+))?})
        if y[0] and y[0][2] then
            real_size = y[0][2]
        end
    }

    # some formats need the end of the file as well
    # small hardcoded list will do for now
    need_end = ['audio/mpeg'].grep curl.content_type
    if need_end.size > 0 then
	    curl.headers['Range'] = 'bytes=-16384'
	    curl.follow_location = true
	    curl.perform
        body = body + curl.body_str
    end

    return title_from_text(body)
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
