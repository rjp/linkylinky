require 'uri'

def rule(text, schemes = nil)
    schemes = schemes.nil? ? nil : schemes.to_a
    uris = []
    URI.extract(text, schemes) { |uri|
        u = URI.parse(uri.gsub(/^URL:/, '').gsub(/,$/, ''))
        uris.push u.normalize.to_s
    }
    return uris
end
