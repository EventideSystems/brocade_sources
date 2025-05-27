# frozen_string_literal: true

require 'active_record'
require 'erb'
require 'net/ftp'
require 'yaml'

class Work < ActiveRecord::Base
  self.table_name = 'bookbrainz.work'
  self.primary_key = :bbid

  belongs_to :identifier_set, foreign_key: :identifier_set_id, class_name: 'IdentifierSet'
end

class IdentifierSet < ActiveRecord::Base
  self.table_name = 'bookbrainz.identifier_set'

  has_many :identifier_set_identifiers, foreign_key: :set_id
  has_many :identifiers, through: :identifier_set_identifiers
  has_many :works, foreign_key: :identifier_set_id, class_name: 'Work'
end

class IdentifierSetIdentifier < ActiveRecord::Base
  self.table_name = 'bookbrainz.identifier_set__identifier'

  self.primary_key = [:set_id, :identifier_id]

  belongs_to :identifier_set, foreign_key: :set_id
  belongs_to :identifier, foreign_key: :identifier_id
end

class Identifier < ActiveRecord::Base
  self.table_name = 'bookbrainz.identifier'

  has_many :identifier_set_identifiers, foreign_key: :identifier_id 
  has_many :identifier_sets, through: :identifier_set_identifiers
  has_many :works, through: :identifier_sets

  scope :with_gtin, -> { where(type_id: 11) }
end

# TODO: Add option to run a 'clean' task to remove the BookBrainz database
# and user if they exist, before creating them again.
namespace :bookbrainz do
  desc 'Prepare BookBrainz database'
  task :prepare do
    puts 'Setting up BookBrainz database...'
    
    db_config =
      begin
        content = ERB.new(File.read 'config/database.yml').result
        YAML.load(content, aliases: true)
      end
    
    puts "Database configuration: #{db_config.dig('bookbrainz').inspect}"
    ActiveRecord::Tasks::DatabaseTasks.create(db_config.dig('bookbrainz'))
    # TODO: Add username and password to calls to psql if present in the config/database.yml file
    puts '... database created.'
    puts '... creating BookBrainz user and granting privileges.'
    `echo "create role bookbrainz;" | psql -d bookbrainz`
    `echo "grant all privileges on database bookbrainz to bookbrainz;" | psql -d bookbrainz`

    puts 'BookBrainz database setup complete.'
  end

  desc 'Fetch latest BookBrainz data dump'
  task fetch: :prepare do
    puts 'Retrieving latest BookBrainz data dump...'
    puts '... downloading latest data dump from BookBrainz.org'
    
    ftp = Net::FTP.new('ftp.musicbrainz.org')
    ftp.login
    ftp.chdir('pub/musicbrainz/bookbrainz')
    ftp.getbinaryfile('latest.sql.bz2', 'tmp/data/bookbrainz-latest.sql.bz2', 1024)
    ftp.close
    puts 'Download complete.'
  end

  desc 'Load BookBrainz data dump into the database'
  task load: :fetch do
    puts 'Loading BookBrainz data dump into the database...'
    puts '... loading database.'
    `bzcat tmp/data/bookbrainz-latest.sql.bz2 | psql -d bookbrainz`
    puts '... data loaded into database.'
    puts 'BookBrainz data load complete.'
  end

  desc 'Import data from BookBrainz.org into Brocade'
  task :import do
    puts 'Importing BookBrainz data...'
    
    db_config =
      begin
        content = ERB.new(File.read 'config/database.yml').result
        YAML.load(content, aliases: true)
      end
    
    puts "Database configuration: #{db_config.dig('bookbrainz').inspect}"
    ActiveRecord::Base.establish_connection(db_config.dig('bookbrainz'))

    Identifier.with_gtin.find_each do |identifier|
      puts "Importing identifier: #{identifier.id} - #{identifier.value}"

      puts "  Works count: #{identifier.works.count}"
      identifier.works.each do |work|
        puts "  Work: #{work.bbid} (name: #{work.name})"
      end
      
      # identifier.identifier_sets.find_each do |set|
      #   puts "  Identifier Set: #{set.id}"
      #   set.identifiers.each do |id|
      #     puts "    Identifier: #{id.value}"
      #   end
      # end
    end

    # Work.include(:identifier_set).find_each do |work|
    #   puts "Importing work: #{work.bbid} - #{work.name}"
    #   # Here you would implement the logic to import the work into Brocade.
    #   # This is a placeholder for the actual import logic.
    #   # For example, you might create a new Brocade::Work instance and save it.
    #   # Brocade::Work.create(title: work.title, ...other attributes...)
    # end

    puts 'Import complete.'
  end
end
