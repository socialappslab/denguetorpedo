namespace :export do
  desc "Print manualInstruction.all in a seeds.rb way"
  task :seeds_format => :environment do
    ManualInstruction.order(:id).all.each do |inst|
      puts "ManualInstruction.create(#{inst.serializable_hash.delete_if {|key, value| ['created_at','updated_at','id'].include?(key)}.to_s.gsub(/[{}]/,'')})"
    end
  end
end