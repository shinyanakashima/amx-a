require 'json'
require 'digest'

# mojxml-rs（Rust 実装）が出力する newline-delimited GeoJSON を受け取り、
# 既存 fude.rb と同等の fude レイヤー（ポリゴン）NDJSON に変換する。
# 既存方式（mojxml2geojson + fude.rb）と並行して検証できるよう別スクリプトにしている。
#
# mojxml2geojson との主な差分
# - 筆ID の属性名が mojxml-rs では「筆id」（小文字）になる
# - version 属性は出力されない
# - 任意座標系・地区外・別図はデフォルトで出力されない（grep -v 任意座標 が不要）
# 既存成果物と属性名をそろえるため、出力時に「筆id」を「筆ID」へ正規化する。

pref = ENV['PREF']

# SHA256由来のハッシュ値を、53bit符号なし整数（JavaScriptで安全に扱える範囲）に縮小する。
# 詳細な意図は fude.rb の同名関数を参照。
MAX_SAFE_INTEGER = (1 << 53) - 1  # => 9_007_199_254_740_991
def safe_id(str)
  Digest::SHA256.hexdigest(str)[0, 16].to_i(16) % MAX_SAFE_INTEGER
end

while gets
  f = JSON.parse($_)
  props = f['properties']
  if props
    # mojxml-rs は「筆id」、mojxml2geojson は「筆ID」。両対応とし「筆ID」へ寄せる。
    fude_id = props['筆ID'] || props['筆id']
    if fude_id
      props.delete('筆id')
      props['筆ID'] = fude_id

      # mojxml-rs は zip 群を一括変換するためファイル名（連番）を属性に持たない。
      # global_id は pref・市区町村コード・筆ID から決定的に生成し、pref 内で一意にする。
      uid_str = "#{pref}_#{props['市区町村コード']}_#{fude_id}"
      props['global_id'] = uid_str
      f['id'] = safe_id(uid_str)
    end
  end
  f[:tippecanoe] = {
    :layer => 'fude',
    :minzoom => 12,
    :maxzoom => 16
  }
  print "\x1e#{JSON.dump(f)}\n"
end
