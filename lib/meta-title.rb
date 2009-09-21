require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'
require 'curb'

def make_nice_title(m)
    m['mimetype'] ||= 'text/html'
    p m
    m.keys.each { |i|
        m[i] = m[i].to_a.uniq.first
    }
    mimetype = m['mimetype'].downcase
    majortype = mimetype.gsub(%r{^(.*?)/.*$},'\1')
    def_title = "[#{mimetype}" << (m['size'] ? ', '<<m['size'] : '') << ']'
    title = ''

    case majortype
        when 'image'
           title = ''; post_model = ''; post_exposure = ''
           if m['camera model'] then
               title << m['camera model']
               post_model = ', '
           end
           if m['focal length'] then
               title << post_model << m['focal length']
               post_focal = ', '
               post_model = ''
           end
           if m['exposure'] then
               title << post_model << post_focal << m['exposure']
           end

        when 'audio'
           title = ''; pre_artist = ''; pre_album = ''
           if m['title'] then
               title << '"' << m['artist'] << '"'; pre_artist = ' by '; pre_album = ' off '
           end
           if m['artist'] then
               title << pre_artist << m['artist']
           end
           if m['album'] then
               title << pre_album << '"' << m['album'] << '"'
           end
        when 'text'
            title = m['title']
    end
    p title
    return title.length > 0 ? title : def_title
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

title_x('http://rjp.frottage.org/tmp/sorry.mp3')
title_x('http://rjp.frottage.org/tmp/theme2.mp3')
title_x('http://rjp.frottage.org/catsink.jpg')
title_x('http://rjp.frottage.org/uaposts.png')
title_x('http://frottage.org/mysql/manual.html')
title_x('http://backup.frottage.org/rjp/env.cgi')
title_x('http://theregister.co.uk/content/6/34549.html')
