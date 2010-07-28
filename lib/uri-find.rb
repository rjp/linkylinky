require 'uri'

$uri_find_use_gruber = false

# TODO figure out how to replace the hardcoded Unicode with escapes
$gruber_re_front = %q{(?i)\b(}
$gruber_re_scheme = %q{(?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)}
$gruber_re_back = %q{(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}

# piggyback this onto rule for maximum code re-use
def simple_find(text, schemes = nil)
    # if our housewife expressed a preference, use gruber
    if $uri_find_use_gruber then
        return gruber_find(text, schemes)
    end
    # else stick with the URI.extract that comes with ruby
    a = rule(text, schemes)
    return a.map { |o| o[0] }
end

# use gruber's uri regexp matching as per
# http://daringfireball.net/2010/07/improved_regex_for_matching_urls
# with minor alteration to allow specific scheme matching
def gruber_find(text, schemes = nil)
    schemes = schemes.nil? ? nil : schemes.to_a
    if schemes.nil? then
        scheme_re = $gruber_re_scheme
    else
        scheme_alt = schemes.join('|')
        scheme_re = "(?:(?:#{scheme_alt}):(?:/{1,3}))"
    end
    scheme_rec = $gruber_re_front + scheme_re + $gruber_re_back
    gruber_re = Regexp.new(scheme_rec)
    return text.scan(gruber_re).map { |o| o[0] }
end

def rule(text, schemes = nil)
    schemes = schemes.nil? ? nil : schemes.to_a
    uris = []
    URI.extract(text, schemes) { |uri|
        u = URI.parse(uri.gsub(/^URL:/, '').gsub(/,$/, ''))
        uris.push [u.normalize.to_s, u]
    }
    return uris
end
