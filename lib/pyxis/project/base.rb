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

        def github_repository_name
          github_path.split('/')[1]
        end

        def api_gitlab_path
          paths[:gitlab].gsub('/', '%2F')
        end

        def component_name
          # noinspection RubyNilAnalysis
          name.split('::').last.downcase
        end
      end
    end

    def self.components
      %i[aquila draco sagittarius sculptor taurus]
    end

    def self.get_project(project)
      const_get(project.capitalize)
    end
  end
end
