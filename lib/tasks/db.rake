require './spec/support/data_helper.rb'

namespace :db do
  namespace :development do
    desc "Populate with dummy data"
    task :prepare => [:environment] do
      ENV["RAILS_ENV"] ||= "development"

      ['db:drop', 'db:create'].each do |s|
        Rake::Task[s].invoke
      end

      # populate_data()
      # Run heroku pgbackups:url -a denguetorpedo to get the URL
      dev_dump_path = Rails.root + "db/development.dump"
      unless File.exist?(dev_dump_path)
        heroku_backup_url = %x(heroku pgbackups:url -a denguetorpedo)
        f = File.new(dev_dump_path)
        f.write(open(heroku_backup_url).read)
        f.close
      end

      %x(pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d denguechat_dev #{dev_dump_path})
      Rake::Task['db:migrate'].invoke
    end
  end
end
