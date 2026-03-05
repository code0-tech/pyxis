# frozen_string_literal: true

module Pyxis
  module Checks
    class CanaryRelease < AggregatedCheck
      def initialize(build_id_to_promote)
        info = Pyxis::ManagedVersioning::ComponentInfo.new(build_id: build_id_to_promote)
        super(
          'Canary release',
          [
            TucanaVersionMatch.new(info),
            OpenIssues.new('release blocking', ['blocks-releases'])
          ]
        )
      end
    end
  end
end
