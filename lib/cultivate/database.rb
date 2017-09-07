
require 'sequel'
require 'sqlite3'

module Cultivate
  Database = Class.new(Sequel::Model)
  PatientColumns = %i[
    accepted_date
    room
    number
    name
    sample
    item
    bacteria
    comment
    application_date
    bed
    reqno
    serialno
    amount
  ]

  class Database
    def self.create_table
      create_patients
      create_test_results
    end

    def self.create_patients
      db.create_table :patients do
        primary_key :id

        PatientColumns.each do |name|
          case name
          when :reqno
            column name, String, :null => true
          else
            column name, String, :null => false
          end
        end

        index [:serialno, :application_date], :unique => true
      end
    end

    def self.create_test_results
      db.create_table :test_results do
        primary_key :id
        foreign_key :patient_id, :patients, :null => false

        column :value, String, :null => false
      end
    end
  end
end
