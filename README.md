# amx-a
法務省が提供する登記所備付地図データからベクトルタイル（`PMTiels`）を生成するコンテナを提供する。
[amx-a](https://github.com/amx-project/a)をコンテナで動かせるようにし、独自のIDを附番できるようにした。

# Demo
[登記所備付地図ツール Mabiki2.0](https://zksdx.org/map/mabiki/v2.0/mojmap-mabiki-2.0-vanilla/)
<img width="1905" height="982" alt="image" src="https://github.com/user-attachments/assets/b90bc0b3-7b66-4b0f-ab08-b3cc102d9b25" />

### build

```bash
podman compose build
```

### run & debug

```bash
podman compose up
```

#### debug

```bash
podman compose run --rm --entrypoint /bin/bash tile-builder-mojxml
```

- Test run: `stream.rb`

```bash
# PREF=01 TYPE=daihyo ruby stream.rb
```

- Test run:`rake` task
```bash
podman compose run --rm tile-builder-mojxml rake mbtiles
podman compose run --rm tile-builder-mojxml rake pmtiles
podman compose run --rm tile-builder-mojxml rake style
```

### Tips
#### for generation the `Gemfile.lock`

```bash
podman run --rm -v ".:/usr/src/app" -w /usr/src/app ruby:3.1-slim bundle install
```

〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️


## Document
https://github.com/amx-project/a-spec

## What is behind the repository name?
[Most UNIX C compilers link executables by default to a file called "a.out".](https://stackoverflow.com/questions/1218262/why-do-some-compilers-use-a-out-as-the-default-name-for-executables) That is why. 
