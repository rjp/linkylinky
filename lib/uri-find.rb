require 'uri'

# piggyback this onto rule for maximum code re-use
def simple_find(text, schemes = nil)
    a = rule(text, schemes)
    return a.map { |o| o[0] }
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
