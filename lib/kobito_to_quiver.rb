require 'sqlite3'
require 'fileutils'
require '../lib/kobito_item'
class KobitoToQuiver
  OUTPUT_DIR = File.expand_path('../../output/', __FILE__).freeze

  def run
    items = find_items
    output_files(items)
  end

  def output_files(items)
    init_dir
    items.each do |pk, item|
      puts "#{pk} / #{item.title}"
      next if item.temp?
      path = File.join(OUTPUT_DIR, "#{pk}.md")
      File.write(path, item.body)
    end
  end

  def init_dir
    if File.exists?(OUTPUT_DIR)
      puts "delete #{OUTPUT_DIR}"
      FileUtils.rm_rf(OUTPUT_DIR)
    end
    FileUtils.mkdir(OUTPUT_DIR)
  end

  def find_items
    sql = <<~SQL
      SELECT
        Z_PK,
        ZTITLE,
        ZIN_TRASH,
        ZRAW_BODY,
        ZCREATED_AT,
        ZUPDATED_AT,
        ZUPDATED_AT_ON_QIITA,
        ZURL
      FROM
        ZITEM
      WHERE
        ZIN_TRASH IS NULL
      ORDER BY
        ZUPDATED_AT DESC
      LIMIT 10
    SQL
    run_query(sql).map { |row|
      item = KobitoItem.new
      item.pk = row['Z_PK']
      item.raw_created_at = row['ZCREATED_AT']
      item.raw_updated_at = row['ZUPDATED_AT']
      item.raw_body = row['ZRAW_BODY']
      item.title = row['ZTITLE']
      item.url = row['ZURL']
      find_tags(item.pk) do |tag|
        item.tags << tag
      end
      [item.pk, item]
    }.to_h
  end

  def find_tags(pk)
    sql = <<~SQL
      SELECT ZNAME
      FROM ZITEM
        INNER JOIN Z_2TAGS
          ON ZITEM.Z_PK = Z_2TAGS.Z_2ITEMS
        INNER JOIN ZTAG
          ON Z_2TAGS.Z_3TAGS = ZTAG.Z_PK
      WHERE
        ZITEM.Z_PK = ?
    SQL
    run_query(sql, pk).each do |row|
      yield row['ZNAME']
    end
  end

  def run_query(sql, *params)
    statement = db.prepare(sql)

    enum = statement.execute(params)
    return enum unless block_given?
    enum.each do |row|
      yield row
    end
  end

  def db
    @db ||= SQLite3::Database.new(db_path).tap do |_db|
      _db.results_as_hash = true
    end
  end

  def db_path
    File.expand_path('../../db/Kobito.db', __FILE__)
  end
end

KobitoToQuiver.new.run