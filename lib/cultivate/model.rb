
require 'csv'

module Cultivate
  class Attributes < Struct.new(:patient, :test_results)
    def initialize row
      super(
        Hash[PatientColumns.zip(row)],
        row.drop(PatientColumns.size).compact)
    end
  end

  class Patient < Database
    BeginOfData = 4
    OffsetId = 2

    unrestrict_primary_key
    one_to_many :test_results

    def self.import path
      load_rows(path).each do |row|
        begin
          process(row)
        rescue Sequel::NotNullConstraintViolation => e
          warn "File '#{path}' contains a row without an id. Row: #{row}"
        end
      end
    end

    def self.load_rows path
      CSV.read(path).drop(BeginOfData).inject([]) do |result, row|
        if row.first
          result << row
        else # fix broken data by concating the last row
          result << result.pop + row
        end
      end
    end

    def self.process row
      if patient = self[row[OffsetId]]
        update(patient, row)
      else
        insert(row)
      end
    end

    def self.update patient, row
      attributes = Attributes.new(row)

      patient.update(attributes.patient)
      TestResult.insert(patient, attributes.test_results)
    end

    def self.insert row
      attributes = Attributes.new(row)

      patient = Patient.create(attributes.patient)
      TestResult.insert(patient, attributes.test_results)
    end
  end

  class TestResult < Database
    many_to_one :patient

    def self.insert patient, test_results
      test_results.each do |result|
        create(:patient => patient, :value => result)
      end
    end
  end
end
