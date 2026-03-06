# frozen_string_literal: true

module Pyxis
  module Checks
    class AggregatedCheck
      include Check

      attr_reader :check_context, :checks

      def initialize(check_context, checks)
        @check_context = check_context
        @checks = checks
      end

      def perform_check!
        checks.all?(&:pass?)
      end

      def status_message
        message = []
        message << if pass?
                     "#{icon} #{check_context} checks pass"
                   else
                     "#{icon} #{check_context} checks fail"
                   end
        checks.each do |check|
          message << ''
          message << check.status_message
        end

        message.join("\n")
      end
    end
  end
end
