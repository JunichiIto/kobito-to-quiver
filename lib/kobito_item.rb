require 'active_support/core_ext/integer'
require 'active_support/core_ext/time'

class KobitoItem
  attr_accessor :pk, :raw_created_at, :raw_updated_at, :raw_body, :title, :url, :tags

  def initialize
    @tags = []
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

  def to_time(unix_time)
    Time.at(unix_time) + 31.years
  end
end