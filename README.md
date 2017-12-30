# kobito-to-quiver

Migrate Kobito data to Quiver.

[Kobito](http://blog.qiita.com/post/168180042619/kobito-for-mac-windows%E3%81%AE%E6%8F%90%E4%BE%9B%E5%8F%8A%E3%81%B3%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC%E3%82%B5%E3%83%9D%E3%83%BC%E3%83%88%E3%82%92%E7%B5%82%E4%BA%86%E3%81%97%E3%81%BE%E3%81%99)のデータを[Quiver](http://happenapps.com/)に移行するためのサポートツールです。

## Setup

```
# Ruby 2.4 or higher
$ ruby -v

$ bundle install
```

## 免責事項

このツールを使って何らかの損害が発生しても、作者は責任を負いません。

## 制限事項

Qiita::Team用のKobitoデータの移行はこのツールの動作対象外です。（作者がQiita::Teamを利用していないため）

## 手順

### Kobitoのdbファイルをdbディレクトリにコピーする

```
$ cp ~/Library/Containers/com.qiita.Kobito/Data/Library/Kobito/Kobito.db ./db
```

### KobitoのデータをMarkdownとしてエクスポートする

以下のコマンドを実行するとoutputディレクトリに記事がMarkdownファイルとしてエクスポートされる。

```
$ bundle exec rake export
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

<img width="717" alt="screen shot 2017-12-30 at 20 31 34" src="https://user-images.githubusercontent.com/1148320/34453818-7c579f24-eda0-11e7-9d33-64c4f6d918bc.png">

この時点ではタイトルは数字で、タグはインポートされない。

### Quiverのqvnotebookディレクトリをコピーする

上でインポートしたNotebookを確認する。（以下の例で言うと、"FAEFB235"で始まる作成日時が一番若いqvnotebookディレクトリがそれ）

```
$ ls -lt ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary/ | grep .qvnotebook
drwxr-xr-x@ 787 jit  staff  25184 Dec 30 20:31 FAEFB235-9A6F-4771-AF03-6685EEC2212E.qvnotebook
drwxr-xr-x@   3 jit  staff     96 Dec 30 18:57 Trash.qvnotebook
drwxr-xr-x@ 787 jit  staff  25184 Dec 30 18:55 B6A3F526-F4F6-4D18-9D76-F7D122BD1C1E.qvnotebook
drwxr-xr-x@   3 jit  staff     96 Dec 30 06:03 Inbox.qvnotebook
drwxr-xr-x@  15 jit  staff    480 Dec 30 05:59 Tutorial.qvnotebook
```

qvnotebookディレクトリにコピーする。

```
$ cp -r ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary/(対象のqvnotebook).qvnotebook ./qvnotebook
```

### qvnotebook内のファイルをアップデートする

以下のコマンドを実行すると、各記事のタイトルとタグが更新される。

```
$ bundle exec rake update_qvnotebook
```

なお、Qiitaに投稿したことのある記事は`qiita-published`のタグも付与されます。

```./lib/quiver_updator.rb
def update_meta_json(dir)
  update_json(dir, 'meta.json') do |json_data, item|
    json_data['title'] = item.title
    json_data['created_at'] = item.created_at.to_i
    json_data['updated_at'] = item.updated_at.to_i
    json_data['tags'] = item.tags
    # Qiitaに投稿されていれば"qiita-published"のタグも付ける
    if item.qiita_published?
      json_data['tags'] << 'qiita-published'
    end
  end
end
```

### qvnotebookディレクトリを元に戻す

念のためQuiverを終了させる。

続いて、先ほどのqvnotebookディレクトリを元に戻す。

```
$ cp -rf ./qvnotebook/(対象のqvnotebook).qvnotebook ~/Library/Containers/com.happenapps.Quiver/Data/Library/Application\ Support/Quiver/Quiver.qvlibrary/
```

### 移行が成功したことを確認する

Quiverを起動し、インポートした記事のタイトルやタグが更新されていることを確認する。（以下のスクリーンショットではインポート時に作成されたNotebook名をKobitoに変えています）

<img width="1769" alt="screen shot 2017-12-30 at 18 58 08" src="https://user-images.githubusercontent.com/1148320/34453281-851a0258-ed93-11e7-98da-84f134a3fa97.png">

## License

MIT License.