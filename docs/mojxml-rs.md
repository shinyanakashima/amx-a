# mojxml-rs 導入による前段処理の Rust 化（構成メモ）

地図XML → GeoJSON/NDJSON 変換の前段を [`KotobaMedia/mojxml-rs`](https://github.com/KotobaMedia/mojxml-rs)
（Rust 実装・MIT License）へ置き換えた構成。`rake mbtiles` が mojxml-rs 方式（既定）で、
旧方式（`mojxml2geojson` + `fude.rb` / `daihyo.rb`）は `rake mbtiles_legacy` としてフォールバック・比較用に残している。

## 構成

| 役割 | 旧方式（legacy） | mojxml-rs 方式（既定） |
| --- | --- | --- |
| XML → GeoJSON | `mojxml2geojson`（Python, zip ごと） | `mojxml-rs`（Rust, zip 群を一括・並列） |
| fude 後処理 | `fude.rb` | `fude_from_mojxml_rs.rb` |
| daihyo 後処理 | `daihyo.rb` | `daihyo_from_mojxml_rs.rb` |
| Rake task | `rake mbtiles_legacy` | `rake mbtiles` |

`rake pmtiles` / `rake style` は両方式で共通（成果物は `output/{pref}.mbtiles` に揃える）。

## mojxml-rs 方式の流れ

```text
mojxml-rs で pref 単位の raw NDJSON を作成（output/{pref}.raw.geojson）
→ raw から daihyo レイヤー生成（daihyo_from_mojxml_rs.rb）
→ raw から fude レイヤー生成（fude_from_mojxml_rs.rb）
→ tippecanoe
→ tile-join → output/{pref}.mbtiles
```

XML パースは pref あたり 1 回のみ。既存方式は daihyo / fude で `stream.rb` を 2 回走らせ、XML を
二重パースしていたが、その重複を解消している。

## FGB 生成パイプライン（geo-ditto-fgb）との連携

表示用の PMTiles とは別に、地物選択→エクスポートのために
[`geo-ditto-fgb`](https://github.com/shinyanakashima/geo-ditto-fgb) が FlatGeobuf を生成する。
PMTiles と FGB は**同一の `global_id` で突合**するため、両者は同じ NDJSON 由来である必要がある。

`mbtiles` タスクでは `fude_from_mojxml_rs.rb` に `NDJSON_OUT=tmp` を渡し、tippecanoe へ流すのと
同じ NDJSON を、市区町村コード単位で次の場所に保存する。

```text
tmp/{pref}/{市区町村コード}/{市区町村コード}.ndjson
```

`geo-ditto-fgb` はこの階層を走査して市区町村コード単位の FGB を作り、`merged.fgb` に統合する。

- `global_id` を持つ地物のみ書き出す（マッチング不能な地物は除外）。
- 市区町村コード単位に分割するのは、FGB 1 ファイルあたりのサイズ・メモリを抑えるため。
- 可視化アプリは `merged.fgb` を読み、`global_id` で PMTiles の選択地物と突合する。
  そのため FGB の個別ファイル名は内部的な詳細で、アプリには影響しない。

## 出力フォーマットの差分（mojxml2geojson との比較）

- `mojxml-rs` は newline-delimited GeoJSON を出力する（`tippecanoe-json-tool` での分割は不要）。
- 任意座標系・地区外・別図はデフォルトで除外される（`grep -v 任意座標` 相当）。
  含める場合は `-a` / `-A` / `-c` オプションを使う。
- 筆IDの属性名が `筆id`（小文字）。`version` 属性は出力されない。
  - `fude_from_mojxml_rs.rb` で `筆id` を `筆ID` へ正規化し、既存成果物と属性名を揃える。
- `代表点緯度` / `代表点経度` は出力されるため、daihyo の代表点生成は既存と同じ方針で行える。
- `global_id` は `{pref}_{市区町村コード}_{筆ID}` から決定的に生成する。
  `mojxml-rs` は zip を一括変換しファイル名（連番）を持たないため、既存の `{pref}_{basename}_{筆ID}` とは
  ID 値が変わる点に注意（pref 内での一意性・決定性は保たれる）。

## 1 zip での差分確認（Step 2）

```bash
# 既存方式
TYPE=fude   PREF=01 ruby to_geojson.rb src/path/to/01101-4300-1.zip > old-fude.ndjson
TYPE=daihyo PREF=01 ruby to_geojson.rb src/path/to/01101-4300-1.zip > old-daihyo.ndjson

# mojxml-rs 方式
mojxml-rs output/01.raw.geojson src/path/to/01101-4300-1.zip
cat output/01.raw.geojson | PREF=01 ruby fude_from_mojxml_rs.rb   > new-fude.ndjson
cat output/01.raw.geojson | PREF=01 ruby daihyo_from_mojxml_rs.rb > new-daihyo.ndjson

# 件数・属性差分の確認例
wc -l old-fude.ndjson new-fude.ndjson
```

## ベンチマーク

```bash
START_PREF=1 END_PREF=1 /usr/bin/time -v rake mbtiles_legacy   # 旧方式
START_PREF=1 END_PREF=1 /usr/bin/time -v rake mbtiles          # mojxml-rs 方式（既定）
/usr/bin/time -v rake pmtiles
```

比較対象：1 zip / 1 市区町村 / 北海道全体（pref=01）で、旧方式と mojxml-rs 方式の処理時間・メモリ使用量・
成果物（件数・属性・ID・見た目）を確認する。

> 大規模データで `/tmp` の容量が足りない場合は `mojxml-rs -t <dir> ...` で展開先を指定する。

## 切り替え

- 既定は `rake mbtiles`（mojxml-rs 方式）。`docker-compose.yaml` もこれを呼ぶ。
- 旧方式に戻す場合は `rake mbtiles_legacy` を使う。
- どちらも `output/{pref}.mbtiles` を生成するため、比較する際は出力先を分けるか、片方ずつ実行する。
- `mojxml-rs` バイナリのバージョンは Dockerfile の `MOJXML_RS_VERSION`（既定 `v0.3.0`）で固定している。
