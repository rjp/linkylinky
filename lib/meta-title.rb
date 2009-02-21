require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'
require 'curb'

def title(uri)
    x=''
    open(uri, :progress_proc => lambda{|x|p x}) { |fh|
        x = fh.read(12)
        break
    }
    p x
end

def title_x(uri)
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


    # write the body to a tempfile
    Tempfile.open('lnkylnky', '/tmp') { |t|
        t.print body
        t.flush
        metadata = Extractor.extract(t.path)
        p metadata
        t.close!
    }
end

title_x('http://rjp.frottage.org/tmp/sorry.mp3')
title_x('http://rjp.frottage.org/tmp/theme2.mp3')
title_x('http://rjp.frottage.org/catsink.jpg')
title_x('http://rjp.frottage.org/uaposts.png')
title_x('http://frottage.org/mysql/manual.html')
title_x('http://backup.frottage.org/rjp/env.cgi')
title_x('http://theregister.co.uk/content/6/34549.html')
