require 'uri-find'
require 'test/unit'

class TC_uri_find_simple_find < Test::Unit::TestCase
    @@bitly = "Sample text with http://microsoft.com/ and bit.ly/microsoft links"

    def test_bitly
        $uri_find_use_gruber = true
        a = simple_find(@@bitly)
        assert_equal(2, a.size, '2 urls including bit.ly')
        assert_equal(a[0], 'http://microsoft.com/')
        assert_equal(a[1], 'bit.ly/microsoft')

        $uri_find_use_gruber = false
        a = simple_find(@@bitly)
        assert_equal(1, a.size, '1 url not including bit.ly')
        assert_equal(a[0], 'http://microsoft.com/')
        assert_equal(nil, a[1])
    end
end
