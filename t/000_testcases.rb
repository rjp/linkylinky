require 'uri-find'
require 'test/unit'

class TC_uri_find_rule < Test::Unit::TestCase
	png = 'http://ipy.frottage.org/rjp/2003/09/07/definitely.png'
	cgi = 'http://ipy.frottage.org/cgi-bin/rjp/env.cgi?query=frottage'
	fragment = 'http://ipy.frottage.org/rjp/#page1'
	ldap = 'ldap://server/o=frottage.org?uid?sub?(uid=%s)'
	news = 'news://news.easynet.co.uk/slrnbnntv2.1n95.rjp@ipy.frottage.org'
	nntp = 'nntp:slrnbnntv2.1n95.rjp@ipy.frottage.org'
	auth = 'http://rjp:badgers@localhost.pi.st/secret/stash/'
	ssl = 'https://hotmail.com/'
	@@text = <<TEST_TEXT
this is some text with embedded links to people I know, http://husk.org/,
places I run, http://browser.org/, helpful ftp sites, ftp://ftp.debian.org/,
a png that helps people to spell, #{png}, a cgi, #{cgi}, a page fragment, 
#{fragment}, and some miscellaneous other URLS -- #{ldap}, #{news}, #{nntp}, 
#{auth}, #{ssl}.
TEST_TEXT
    def test_http_scheme
        a = rule(@@text, 'http') 
        assert_equal(6, a.size, '6 http urls')
        assert_equal('http://husk.org/', a[0])
        assert_equal('http://browser.org/', a[1])
    end

    def test_ftp_scheme
        a = rule(@@text, 'ftp') 
        assert_equal(1, a.size, '1 ftp url')
        assert_equal('ftp://ftp.debian.org/', a[0])
    end

    def test_no_scheme
        a = rule(@@text)
        assert_equal(11, a.size, '11 urls')
    end
end
