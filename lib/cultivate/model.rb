
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
    CommentOffset = 7

    one_to_many :test_results

    def self.import path
      load_rows(path).each do |row|
        begin
          attributes = Attributes.new(fix_row(row))
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
      find(:serial => attributes.patient[:serial],
           :application_date => attributes.patient[:application_date])
    end

    def self.fix_row row
      stripped_row = row.map{ |r| if r then r.strip else r end }

      # those rows are always correct
      correct_row = stripped_row.first(CommentOffset)

      # find where the application date should be
      application_date_index =
        correct_row.size +
        stripped_row[CommentOffset..-1].index do |r|
          r =~ /\A\d{7}\z/
        end

      # construct the correct comment
      comment = stripped_row[CommentOffset...application_date_index].join

      # construct the correct row
      (correct_row << comment).
        concat(stripped_row[application_date_index..-1])
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
