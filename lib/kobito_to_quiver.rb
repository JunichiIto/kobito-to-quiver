require 'sqlite3'
require '../lib/kobito_item'
class KobitoToQuiver
  def run
    items = find_items
    items.each do |item|
      puts item
    end
  end

  def output_files(items)

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
    run_query(sql).map do |row|
      item = KobitoItem.new
      item.pk = row['Z_PK']
      item.raw_created_at = row['ZCREATED_AT']
      item.raw_updated_at = row['ZUPDATED_AT']
      item.body = row['ZRAW_BODY']
      item.title = row['ZTITLE']
      item.url = row['ZURL']
      find_tags(item.pk) do |tag|
        item.tags << tag
      end
      item
    end
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