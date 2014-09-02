require './spec/support/data_helper.rb'

namespace :db do
  namespace :development do
    desc "Populate with dummy data"
    task :prepare => [:environment] do
      ENV["RAILS_ENV"] ||= "development"

      ['db:reset', 'db:create', 'db:schema:load', 'db:seed'].each do |s|
        Rake::Task[s].invoke
      end

      populate_data()
    end
  end
end
