# Range of prefectures based on environment variables
def pref_range
  start_pref = ENV['START_PREF'].to_i
  end_pref = ENV['END_PREF'].to_i
  (start_pref..end_pref).map { |i| sprintf('%02d', i) }
end

# tippecanoe / tile-join コマンド（既存方式と mojxml-rs 方式で共用する）
def daihyo_tippecanoe(pref)
  'tippecanoe --quiet --drop-densest-as-needed ' \
  '-x 筆ID -x version -x 代表点緯度 -x 代表点経度 ' \
  '--minimum-zoom=2 --maximum-zoom=11 ' \
  "-f -o output/#{pref}-daihyo.mbtiles"
end

def fude_tippecanoe(pref)
  'tippecanoe --quiet ' \
  '-x version -x 代表点緯度 -x 代表点経度 ' \
  '--minimum-zoom=12 --maximum-zoom=16 --no-tile-size-limit ' \
  "-f -o output/#{pref}-fude.mbtiles"
end

def join_layers(pref)
  'tile-join --no-tile-size-limit ' \
  "-f -o output/#{pref}.mbtiles " \
  "output/#{pref}-fude.mbtiles output/#{pref}-daihyo.mbtiles"
end

desc 'create mbtiles'
task :mbtiles do
  pref_range.each do |pref|
    next if File.exist?("#{pref}.mbtiles")
    $stderr.print "#{Time.now}: #{pref}\n"
    sh <<-EOS
TYPE=daihyo PREF=#{pref} ruby stream.rb | #{daihyo_tippecanoe(pref)}; \
TYPE=fude PREF=#{pref} ruby stream.rb | #{fude_tippecanoe(pref)}; \
#{join_layers(pref)};
    EOS
  end
end

desc 'create mbtiles using mojxml-rs (Rust frontend)'
task :mbtiles_rs do
  pref_range.each do |pref|
    next if File.exist?("output/#{pref}.mbtiles")
    zips = Dir.glob("src/**/#{pref}*-*-*.zip").sort
    if zips.empty?
      $stderr.print "#{Time.now}: #{pref} skip (no zip)\n"
      next
    end
    $stderr.print "#{Time.now}: #{pref} (#{zips.size} zip)\n"

    raw = "output/#{pref}.raw.geojson"
    # mojxml-rs は zip 群を一括・並列変換し newline-delimited GeoJSON を出力する。
    # 任意座標系・地区外・別図はデフォルトで除外されるため grep -v 任意座標 は不要。
    sh "mojxml-rs #{raw} #{zips.join(' ')}"

    # 1 度の変換結果（raw）から fude / daihyo を生成し、XML の二重パースを避ける。
    sh <<-EOS
cat #{raw} | PREF=#{pref} ruby daihyo_from_mojxml_rs.rb | #{daihyo_tippecanoe(pref)}; \
cat #{raw} | PREF=#{pref} ruby fude_from_mojxml_rs.rb | #{fude_tippecanoe(pref)}; \
#{join_layers(pref)};
    EOS
  end
end

# Get the list of filenames for the target {prefecture_code}.mbtiles
# @return [Array<String>] list of filenames
def files
  list = Dir.glob('output/??.mbtiles').sort.filter {|path|
    !File.exist?("#{path}-journal")
  }
  list
end

desc 'create pmtiles'
task :pmtiles do
  sh <<-EOS
tile-join -f --no-tile-size-limit \
--minimum-zoom=12 --maximum-zoom=16 \
-o output/a-fude.mbtiles #{files.join(' ')}; \
(parallel -P 2 --eta --line-buffer \
"tippecanoe-decode \
-Z 11 -z 11 {} | tippecanoe-json-tool" \
::: #{files.join(' ')}) | \
tippecanoe \
-r3 \
--drop-densest-as-needed \
--minimum-zoom=2 \
--maximum-zoom=11 \
--layer=daihyo \
-f -o output/a-daihyo.mbtiles; \
tile-join -f --no-tile-size-limit -o output/amx-a_all.mbtiles output/a-fude.mbtiles output/a-daihyo.mbtiles; \
pmtiles convert output/amx-a_all.mbtiles output/amx-a_all.pmtiles
  EOS
end

desc 'create style.json'
task :style do
  sh <<-EOS
charites build style.yml docs/style.json
  EOS
end

desc 'host the site locally'
task :host do
  sh <<-EOS
budo -d docs
  EOS
end

desc 'rebuid daihyo tiles'
task :rebuild do
  sh <<-EOS
echo #{files}
  EOS
end

