# frozen_string_literal: true

module Pyxis
  module Services
    class CreateReticulumBuildService
      InvalidVersionOverride = Class.new(Pyxis::Error)

      include SemanticLogger::Loggable

      attr_reader :version_overrides, :ref

      def initialize(version_overrides, ref: Project::Reticulum.default_branch)
        @version_overrides = version_overrides
        @ref = ref
      end

      def execute
        logger.info('Creating build with version overrides', version_overrides: version_overrides)

        version_overrides.each_pair do |component, version|
          validate_override!(component, version)
        end

        pipeline = GitlabClient.client.create_pipeline(
          Project::Reticulum.api_gitlab_path,
          ref,
          variables: version_override_variables + token_variable,
        )

        pipeline.body if pipeline.response.status == 201
      end

      private

      def validate_override!(component, version)
        project = Pyxis::Project.const_get(component.capitalize)

        begin
          GithubClient.octokit.tag(project.github_path, version)
        rescue Octokit::UnprocessableEntity, Octokit::NotFound
          begin
            GithubClient.octokit.commit(project.github_path, version)
          rescue Octokit::UnprocessableEntity, Octokit::NotFound
            raise InvalidVersionOverride, "Invalid version '#{version}' for component '#{component}'"
          end
        end
      end

      def version_override_variables
        variables = []

        version_overrides.each_pair do |component, version|
          variables << {
            key: "OVERRIDE_#{component}_VERSION",
            value: version,
          }
        end

        variables
      end

      def token_variable
        [
          {
            key: 'C0_GH_TOKEN',
            value: File.read(ENV.fetch('PYXIS_GH_RETICULUM_PUBLISH_TOKEN')),
          }
        ]
      end
    end
  end
end
