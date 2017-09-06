
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

    one_to_many :test_results

    def self.import path
      load_rows(path).each do |row|
        begin
          attributes = Attributes.new(strip_row(row))
          process(attributes)
        rescue Sequel::NotNullConstraintViolation => e
          warn \
          "\e[31m#{e.message}\e[0m\nFile: #{path}\nAttributes: #{attributes}"
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

    def self.process attributes
      if patient = lookup(attributes)
        update(patient, attributes)
      else
        insert(attributes)
      end
    end

    def self.update patient, attributes
      patient.update(attributes.patient)
      TestResult.insert(patient, attributes.test_results)
    end

    def self.insert attributes
      patient = Patient.create(attributes.patient)
      TestResult.insert(patient, attributes.test_results)
    end

    def self.lookup attributes
      find(:reqno => attributes.patient[:reqno],
           :application_date => attributes.patient[:application_date])
    end

    def self.strip_row row
      row.map{ |r| if r then r.strip else r end }
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
