require './spec/support/data_helper.rb'

namespace :db do
  namespace :development do
    desc "Populate with dummy data"
    task :prepare => [:environment] do
      ['db:reset', 'db:create', 'db:schema:load', 'db:seed'].each { |s| Rake::Task[s].invoke }

      populate_users_and_houses()
      populate_notices_houses_sponsors_and_prizes()
    end
  end
end
