# frozen_string_literal: true

module Pyxis
  module ManagedVersioning
    class ComponentInfo
      include SemanticLogger::Loggable

      attr_reader :build_id

      def initialize(build_id)
        @build_id = build_id
      end

      def execute
        pipeline = GitlabClient.client.get_json(
          "/api/v4/projects/#{Project::Reticulum.api_gitlab_path}/pipelines/#{build_id}"
        )
        reticulum_sha = pipeline.sha

        components = {}

        Pyxis::Project.components.each do |project_name|
          component_project_class = Pyxis::Project.const_get(project_name)
          version_file = "versions/#{component_project_class.component_name}"

          begin
            version_content = GithubClient.octokit.contents(Project::Reticulum.github_path, path: version_file,
                                                                                            ref: reticulum_sha)
            version = Base64.decode64(version_content.content)
            components[component_project_class.component_name] = version
          rescue Octokit::NotFound
            logger.warn("Version file not found for #{component_project_class.component_name} at SHA #{reticulum_sha}")
          end
        end

        components
      end
    end
  end
end
