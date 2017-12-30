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
    json_path = File.join(dir, 'meta.json')
    json_data = open(json_path) do |io|
      JSON.load(io)
    end
    id = json_data['title']
    puts "updating meta.json / #{id}"
    if id !~ /^\d+$/
      puts 'skip.'
      return
    end
    item = kobito_items[id.to_i]
    if item.nil?
      puts 'not found.'
      return
    end
    json_data['title'] = item.title
    json_data['created_at'] = item.created_at.to_i
    json_data['updated_at'] = item.updated_at.to_i
    json_data['tags'] = item.tags
    write_json(json_path, json_data)
  end

  def update_content_json(dir)
    json_path = File.join(dir, 'content.json')
    json_data = open(json_path) do |io|
      JSON.load(io)
    end
    id = json_data['title']
    puts "updating content.json / #{id}"
    if id !~ /^\d+$/
      puts 'skip.'
      return
    end
    item = kobito_items[id.to_i]
    if item.nil?
      puts 'not found.'
      return
    end
    json_data['title'] = item.title
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
