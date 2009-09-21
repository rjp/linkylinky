require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'
require 'curb'

$format_strings = {
    'image' => [
        ['camera model', nil, '', ', '],
        ['focal length', nil, '', ', '],
        ['exposure', nil, '', ', ']
    ],
    'audio' => [
        ['title', '"__X__"', '', ''],
        ['artist', nil, ' by ', ''],
        ['album', '"__X__"', ' off ', ''],
        ['year', nil, ', ', '']
    ]
}

# key, formatter, prefix, postfix
def format_list(m)
    mimetype = m['mimetype'].downcase
    majortype = mimetype.gsub(%r{^(.*?)/.*$},'\1')
    def_title = "[#{mimetype}" << (m['size'] ? ', '<<m['size'] : '') << ']'

    f = $format_strings[majortype]
    if f.nil? then
        return def_title
    end

    title = ''
    added = 0
    previous = ''
    f.each { |k, fm, pr, po|
        if m[k] then
            if added == 1 then
                title << previous
            end
            added = 1
            x = m[k]
            unless fm.nil? then x = fm.gsub('__X__', m[k]); end
            title = title + pr + x
            previous = po
        end
    }

    return title.length > 0 ? title : def_title
end

def make_nice_title(m)
    m['mimetype'] ||= 'text/html'
    p m
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
    p uri
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
    puts real_size

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

#p title_from_uri('http://rjp.frottage.org/tmp/sorry.mp3')
#p title_from_uri('http://rjp.frottage.org/tmp/theme2.mp3')
#title_x('http://rjp.frottage.org/catsink.jpg')
#p title_from_uri('http://rjp.frottage.org/uaposts.png')
#p title_from_uri('http://frottage.org/mysql/manual.html')
#title_x('http://backup.frottage.org/rjp/env.cgi')
#p title_from_uri('http://theregister.co.uk/content/6/34549.html')
p title_from_file('catsink.jpg')
p title_from_file('IMG_4176.JPG')
p title_from_file('04.mp3')
p title_from_file('/cygdrive/d/movies/Farscape - S01E03 - Exodus From Genesis.avi')
