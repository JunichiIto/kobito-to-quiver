require 'sqlite3'
require 'active_support/core_ext/integer'
require 'active_support/core_ext/time'

class KobitoItem
  attr_accessor :pk, :raw_created_at, :raw_updated_at, :raw_body, :title, :url, :tags

  class << self
    def extract_items
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

    private

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

  def initialize
    @tags = []
  end

  def qiita_published?
    !!url
  end

  def temp?
    @tags.include?('temp')
  end

  def to_s
    "pk: #{pk} / title: #{title} / tags: #{tags.join(',')} / updated_at: #{updated_at}"
  end

  def body
    # 先頭行をカット
    regexp = /\A[^\n]+\n+/
    _body = raw_body.sub(regexp, '')
    # Qiitaリンク追加
    unless url.nil?
      _body = "Qiita: #{url}\n\n#{_body}"
    end
    _body
  end

  def created_at
    to_time(raw_created_at)
  end

  def updated_at
    to_time(raw_updated_at)
  end

  private

  def to_time(unix_time)
    Time.at(unix_time) + 31.years
  end
end