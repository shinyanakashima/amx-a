require 'json'
require 'digest'

pref = ENV['PREF']
basename = ENV['BASENAME']

def hash64(str)
  Digest::SHA256.hexdigest(str)[0, 16].to_i(16)
end

while gets
  f = JSON.parse($_)
  if f['properties'] && f['properties']['筆ID']
    uid_str = "#{pref}_#{basename}_#{f['properties']['筆ID']}"
    f['properties']['global_id'] = uid_str
    f['id'] = hash64(uid_str)
  end
  f[:tippecanoe] = {
    :layer => 'fude',
    :minzoom => 14,
    :maxzoom => 16
  }
  print "\x1e#{JSON.dump(f)}\n"
end
