
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
      left = load_rows(path).inject(nil) do |cut_row, row|
        full_row =
          if cut_row
            cut_row.concat(row)
          else
            row
          end

        if fixed_row = fix_row(full_row)
          process(Attributes.new(fixed_row), path)
          nil
        else
          full_row # we try to concat with the next row
        end
      end

      warn "\e[31mLeft row?\e[0m\nFile: #{path}\nRow: #{left}" if left
    end

    def self.load_rows path
      load_csv(path).drop(BeginOfData).inject([]) do |result, row|
        if row.first
          result << row
        else # fix broken data by concating the last row
          result << result.pop + row
        end
      end
    end

    def self.load_csv path
      fixed_csv = read_csv(path).gsub(/,?([^,]*"[^,]*),?/) do |m|
        m.gsub($1, %Q{"#{$1.gsub('"', '""')}"})
      end

      CSV.parse(fixed_csv)
    rescue ArgumentError => e
      warn \
      "\e[31m#{e.message}\e[0m\nFile: #{path}"
    end

    def self.read_csv(path)
      result = File.read(path)

      if result.valid_encoding?
        result
      else
        result.encode('UTF-8', 'BIG5-UAO')
      end
    end

    def self.process attributes, path
      if patient = lookup(attributes)
        update(patient, attributes)
      else
        insert(attributes)
      end
    rescue Sequel::NotNullConstraintViolation => e
      warn \
      "\e[31m#{e.message}\e[0m\nFile: #{path}\nAttributes: #{attributes}"
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
      find(:serialno => attributes.patient[:serialno],
           :application_date => attributes.patient[:application_date])
    end

    def self.fix_row row
      stripped_row = row.map{ |r| if r then r.strip else r end }

      # those rows are always correct
      correct_row = stripped_row.first(CommentOffset)

      # find where the application date should be
      app_date_relative_index =
        stripped_row[CommentOffset..-1].index do |r|
          r =~ /\A\d{7}\z/
        end

      if app_date_relative_index
        app_date_index = app_date_relative_index + correct_row.size

        # construct the correct comment
        comment = stripped_row[CommentOffset...app_date_index].join

        # construct the correct row
        (correct_row << comment).concat(stripped_row[app_date_index..-1])
      else
        # cut row, should be continued with the next row
      end
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
