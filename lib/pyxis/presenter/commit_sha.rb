# frozen_string_literal: true

module Pyxis
  module Presenter
    class CommitSha
      attr_reader :sha

      def initialize(sha)
        @sha = sha
      end

      def as_short
        sha[0...11]
      end
    end
  end
end
