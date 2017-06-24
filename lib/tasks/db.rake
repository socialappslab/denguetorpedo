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

  task :dump, [:db_url] => :environment do |t, args|
    raise "You need to supply a Heroku URL by running heroku config:get DATABASE_URL -a denguetorpedo!" if args[:db_url].blank?

    cmd = nil
    with_config do |app, host, db, user|
      cmd = "pg_dump --verbose --no-owner --no-acl --format=c #{args[:db_url]} > #{Rails.root}/db/#{db}.dump"
    end
    puts cmd
    exec cmd
  end

  task :restore => :environment do |t, args|
    cmd = nil
    with_config do |app, host, db, user|
      cmd = "pg_restore --clean --verbose --no-owner --no-acl --dbname cloviflow_development #{Rails.root}/db/#{db}.dump"
    end
    puts cmd
    exec cmd
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:host],
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username]
  end
end
