
require 'cultivate'
require 'pork/auto'

Cultivate.setup ':memory:'

Pork::API.describe Cultivate::Patient do
  describe '.fix_row' do
    describe 'comment with newline' do
      def broken_rows
        @broken_rows ||= [
          %w[1231212 room number name sample item bacteria broken-comment],
          %w[-continue 1231212 bed reqno serialno amount test results]
        ]
      end

      def concated_row
        @concated_row ||= broken_rows.flatten
      end

      would 'return nil for broken row' do
        expect(Cultivate::Patient.fix_row(broken_rows.first)).eq nil
      end

      would 'concat the comment and return fixed row' do
        fixed = Cultivate::Patient.fix_row(concated_row)

        expect(fixed.size).eq concated_row.size - 1

        attribute = Cultivate::Attributes.new(fixed)

        expect(attribute.patient[:comment]).eq 'broken-comment-continue'
      end
    end
  end
end
