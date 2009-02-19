require 'net/http'
require 'open-uri'
require 'rubygems'
require 'hpricot'

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
    puts res.content_length

    puts "GET"
    req = Net::HTTP::Get.new(url.path)
    req.set_range(0, 1023)
    res = Net::HTTP.start(url.host, url.port) {|x|
        x.request(req)
    }
    puts res.code
    puts res.content_length
    puts res.body.length
    if res.content_type == 'text/html' then
        a = Hpricot(res.body)
        p a.search('title').inner_text.strip
        p a.inner_text.length
    end
end

title_x('http://frottage.org/mysql/manual.html')
#title_x('http://backup.frottage.org/rjp/tmp/big.log')
title_x('http://backup.frottage.org/rjp/env.cgi')
