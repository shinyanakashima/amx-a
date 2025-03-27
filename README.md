# amx-a
Implementation of https://github.com/amx-project/0/issues/4

〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️
## ⚠️Getting Started
G空間で公開されている変換済みGeoJSONには「代表点経度」や「代表点緯度」が付与されていない。
- これら属性は、デジタル庁の登記所備付地図データ変換コンバータ[mojxml2geojson](https://github.com/digital-go-jp/mojxml2geojson)により付与される
- 代表緯度経度が必要な場合は、[amx-a_mojxml](https://github.com/shinyanakashima/amx-a/tree/feature/add-container)を利用する
- 代表緯度経度が不要な場合は、[amx-a_geojson](https://github.com/shinyanakashima/amx-a/tree/develop/add-conversion-from-geojson)を利用する

## Overview
[amx-a](https://github.com/amx-project/a)を動かすためには環境構築が必要であり、それを維持しやすいようにコンテナ化する。

## Development Note
Dockerコンテナにより、[法務省地図XMLアダプトプロジェクト](https://github.com/amx-project/a)のRakefileを実行する。Rakefile内では下記の処理を実行する。

- XMLファイルをGeoJSON形式に変換
  - ※GeoJSONでファイルを入手すればこのステップは不要
- tippecanoeにより、GeoJSONをベクトルタイルに変換
- tile-joinにより、#{pref}-fude.mbtilesと#{pref}-daihyo.mbtilesという2つのタイルセットを統合（#{pref}.mbtiles）
- `pmtiles convert a.mbtiles a.pmtiles`により、mbtilesからpmtilesに変換

### amx-aのtaskと依存関係
Rakefileには5つのタスクが定義されている。
- mbtiles
- pmtiles
- style
- host
- rebuild

#### mbtiles
データをストリームとして出力し、その後 tippecanoe に渡してdaihyo, fudeタイルを生成。
その際にstream.rbを呼び出し、さらに`to_geojson.rb`を呼び出す。
👉ここで`mojxml2geojson`が必要。
https://github.com/amx-project/a/blob/main/stream.rb

#### pmtiles
.mbtiles を .pmtiles に変換。rubyスクリプト呼び出しは無し。

#### style
charites を使用して style.yml から style.json をビルド。rubyスクリプト呼び出しは無し。

#### host
budo を使ってローカルサーバーをホストする。rubyスクリプト呼び出しは無し。

#### rebuild
echo コマンドで files を表示。rubyスクリプト呼び出しは無し。


### build

```bash
podman compose build
# disable cache
#podman compose build --no-cache
```

### run & debug

```bash
podman compose up
```

#### debug
Compose service name is `tile-builder-mojxml`.

```bash
podman compose run --rm --entrypoint /bin/bash {compose_service_name}
```

- Test run: `stream.rb`

```bash
# PREF=01 TYPE=daihyo ruby stream.rb
```

- Test run:`rake` task
```bash
podman compose run --rm {compose_service_name} rake mbtiles
podman compose run --rm {compose_service_name} rake pmtiles
podman compose run --rm {compose_service_name} rake style
```

### Tips
#### for generation the `Gemfile.lock`

```bash
podman run --rm -v ".:/usr/src/app" -w /usr/src/app ruby:3.1-slim bundle install
```

### About data

#### 2024
##### Hokkaido(code`01`)
変換済みGeoJSONのファイル名には、公共座標(JGD2011)が振られている。それをもとに集計した。
11系：43, 12系：102, 13系：44 👉189市区町村

〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️

## Demo
https://amx-project.github.io/a

### PMTiles location on IPFS
QmTZHWMAnRC5zNiNvdVuTDacThKkj4jKbwsZtKQkAC4R69

## Document
https://github.com/amx-project/a-spec

## What is behind the repository name?
[Most UNIX C compilers link executables by default to a file called "a.out".](https://stackoverflow.com/questions/1218262/why-do-some-compilers-use-a-out-as-the-default-name-for-executables) That is why. 
