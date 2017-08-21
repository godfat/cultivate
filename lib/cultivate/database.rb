
require 'sequel'
require 'sqlite3'

module Cultivate
  Database = Class.new(Sequel::Model)
  PatientColumns = %i[
    accepted_date
    room
    id
    name
    sample
    item
    bacteria
    note
    colony
    application_date
    bed
    reqno
    serial
    amount
  ]

  class Database
    def self.create_table
      create_patients
      create_test_results
    end

    def self.create_patients
      db.create_table :patients do
        column :id, String, :primary_key => true, :null => false

        PatientColumns.each do |name|
          next if name == :id

          column name, String, :null => true
        end
      end
    end

    def self.create_test_results
      db.create_table :test_results do
        primary_key :id

        %i[patient_id value].each do |name|
          column name, String, :null => false
        end
      end
    end
  end
end
