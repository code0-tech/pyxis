# frozen_string_literal: true

module Pyxis
  module Checks
    module Check
      def perform_check!
        raise NotImplementedError
      end

      def status_message
        raise NotImplementedError
      end

      def pass?
        return @pass if defined?(@pass)

        @pass = perform_check!
      end

      def icon
        if pass?
          pass_icon
        else
          fail_icon
        end
      end

      def pass_icon
        '✅' # :white_check_mark:
      end

      def fail_icon
        '❌' # :x:
      end
    end
  end
end
