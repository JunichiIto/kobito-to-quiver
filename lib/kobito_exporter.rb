require 'fileutils'
require '../lib/kobito_item'

class KobitoExporter
  OUTPUT_DIR = File.expand_path('../../output/', __FILE__).freeze

  def run
    items = KobitoItem.extract_items
    output_files(items)
  end

  private

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
end

KobitoExporter.new.run