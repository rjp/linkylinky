require 'net/http'
require 'open-uri'
require 'rubygems'
require 'extractor'
require 'tempfile'

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
    puts "HEAD"
    z = ''
    url = URI.parse(uri)
    req = Net::HTTP::Head.new(url.path)
#    req.set_range(0, 119)
    res = Net::HTTP.start(url.host, url.port) {|x|
        x.request(req)
    }
    puts res.code

    puts "GET"
    req = Net::HTTP::Get.new(url.path)
    req.set_range(0, 16383)
    res = Net::HTTP.start(url.host, url.port) {|x|
        x.request(req)
    }
    puts res.code
    puts res.content_type
    body = res.body

    # some formats need the end of the file as well
    # small hardcoded list will do for now
    need_end = ['audio/mpeg'].grep res.content_type
    if need_end.size > 0 then
	    puts "GET"
	    req = Net::HTTP::Get.new(url.path)
	    req.set_range(-16384)
	    p req
	    endres = Net::HTTP.start(url.host, url.port) {|x|
	        x.request(req)
	    }
	    puts endres.code
        body = body + endres.body
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
