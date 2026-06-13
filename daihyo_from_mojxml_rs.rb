require 'json'

# mojxml-rs（Rust 実装）が出力する newline-delimited GeoJSON を受け取り、
# 既存 daihyo.rb と同等の daihyo レイヤー（代表点ポイント）NDJSON に変換する。
# 代表点経度 / 代表点緯度 から Point Feature を生成する方針は既存と同じ。

while gets
  f = JSON.parse($_)
  props = f['properties'] || {}
  pt = {
    :type => 'Feature',
    :tippecanoe => {
      :layer => 'daihyo',
      :minzoom => 2,
      :maxzoom => 11
    },
    :properties => {},
    :geometry => {
      :type => 'Point',
      :coordinates => [
        props['代表点経度'],
        props['代表点緯度']
      ]
    }
  }
  print "\x1e#{JSON.dump(pt)}\n"
end
