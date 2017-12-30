require 'pathname'
require 'json'
require './lib/kobito_item'

class QuiverUpdater
  NOTEBOOK_DIR = File.expand_path('../../qvnotebook', __FILE__).freeze

  def run
    pattern = File.join(NOTEBOOK_DIR, '**/*.qvnote')
    Dir.glob(pattern).each do |dir|
      update_meta_json(dir)
      update_content_json(dir)
    end
  end

  private

  def update_meta_json(dir)
    update_json(dir, 'meta.json') do |json_data, item|
      json_data['title'] = item.title
      json_data['created_at'] = item.created_at.to_i
      json_data['updated_at'] = item.updated_at.to_i
      json_data['tags'] = item.tags
      if item.qiita_published?
        json_data['tags'] << 'qiita-published'
      end
    end
  end

  def update_content_json(dir)
    update_json(dir, 'content.json') do |json_data, item|
      json_data['title'] = item.title
    end
  end

  def update_json(dir, file_name)
    json_path = File.join(dir, file_name)
    json_data = open(json_path) do |io|
      JSON.load(io)
    end
    id = json_data['title']
    puts "updating #{file_name} / #{id}"
    if id !~ /^\d+$/
      puts 'skip.'
      return
    end
    item = kobito_items[id.to_i]
    if item.nil?
      puts 'not found.'
      return
    end
    yield json_data, item
    write_json(json_path, json_data)
  end

  def write_json(json_path, json_data)
    # p json_data
    open(json_path, 'w') do |io|
      io.write(JSON.pretty_generate(json_data))
    end
  end

  def kobito_items
    @kobito_items ||= KobitoItem.extract_items
  end
end
