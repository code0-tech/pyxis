# frozen_string_literal: true

module Pyxis
  module Project
    class Base
      class << self
        def paths
          raise NotImplementedError
        end

        def default_branch
          'main'
        end

        def github_path
          paths[:github]
        end

        def component_name
          # noinspection RubyNilAnalysis
          name.split('::').last.downcase
        end
      end
    end
  end
end
