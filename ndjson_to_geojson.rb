require 'json'

features = []

ARGF.each do |line|
  line.sub!("\x1e", '')
  features << JSON.parse(line)
end

puts JSON.pretty_generate({
  type: 'FeatureCollection',
  features: features
})

