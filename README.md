# kobito-to-quiver

Migrate Kobito data to Quiver.

KobitoのデータをQuiverに移行するためのサポートツールです。

## Setup

```
# Ruby 2.4 or higher
$ ruby -v

$ bundle install
```

## 免責事項

このツールを使って何らかの損害が発生しても、作者は責任を負いません。

## 手順

### Kobitoのdbファイルをdbフォルダにコピーする

```
$ cp ~/Library/Containers/com.qiita.Kobito/Data/Library/Kobito/Kobito.db ./db
```

### KobitoのデータをMarkdownとしてエクスポートする

以下のコマンドを実行するとoutputフォルダに記事がMarkdownファイルとしてエクスポートされる。

```
$ rake export
```

なお、記事に`temp`というタグが付いていると出力をスキップするようにしている。

```./lib/kobito_exporter.rb
def output_files(items)
  init_dir
  items.each do |pk, item|
    puts "#{pk} / #{item.title}"
    # 出力をスキップ
    next if item.temp?
    path = File.join(OUTPUT_DIR, "#{pk}.md")
    File.write(path, item.body)
  end
end
```

また、KobitoからQiitaに送信した記事はファイルの冒頭にQiitaへのリンクを付与している。

### QuiverにMarkdownファイルをインポートする

Quiverを起動 &gt; File &gt; Import &gt; Markdown で、上で出力したMarkdownをインポートする。

この時点ではタイトルは数字で、タグはインポートされない。

### Quiverのqvnotebookディレクトリをコピーする

上でインポートしたNotebookを確認する。（以下の例で言うと、"D61E1411"で始まる作成日時が一番若いqvnotebookディレクトリがそれ）

```
$ ls -la ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary
total 8
drwxr-xr-x@  9 jit  staff  288 Dec 30 18:23 .
drwxr-xr-x@  9 jit  staff  288 Dec 30 17:57 ..
drwxr-xr-x@ 12 jit  staff  384 Dec 30 17:51 6AB38D2B-32F6-47BE-9F46-96A6E6997E02.qvnotebook
drwxr-xr-x@ 12 jit  staff  384 Dec 30 18:23 D61E1411-6259-426F-9D1B-B9558C992C27.qvnotebook
drwxr-xr-x@  3 jit  staff   96 Dec 30 06:03 Inbox.qvnotebook
drwxr-xr-x@ 17 jit  staff  544 Dec 30 17:51 Trash.qvnotebook
drwxr-xr-x@ 15 jit  staff  480 Dec 30 05:59 Tutorial.qvnotebook
-rw-r--r--@  1 jit  staff  220 Dec 30 18:23 meta.json
```

qvnotebookディレクトリにコピーする。

```
$ cp -r ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary/(対象のqvnotebook).qvnotebook ./qvnotebook
```

### qvnotebook内のファイルをアップデートする

以下のコマンドを実行すると、各記事のタイトルとタグが更新される。

```
$ rake update_qvnotebook
```

### qvnotebookディレクトリを元に戻す

念のためQuiverを終了させる。

続いて、先ほどのqvnotebookディレクトリを元に戻す。

```
$ cp -rf ./qvnotebook/(対象のqvnotebook).qvnotebook ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary/
```

### 移行が成功したことを確認する

Quiverを起動し、インポートした記事のタイトルやタグが更新されていることを確認する。

<img width="1769" alt="screen shot 2017-12-30 at 18 58 08" src="https://user-images.githubusercontent.com/1148320/34453281-851a0258-ed93-11e7-98da-84f134a3fa97.png">

## License

MIT License.