# frozen_string_literal: true

module Pyxis
  module Release
    class Canary
      include SemanticLogger::Loggable

      def create_build_branch(build_to_promote)
        component_information = Pyxis::ManagedVersioning::ComponentInfo.new(
          build_id: build_to_promote
        ).execute

        raise 'Build not found' if component_information.nil?

        GitlabClient.client.create_branch(
          Project::Reticulum.api_gitlab_path,
          "pyxis/canary-build/#{build_to_promote}",
          component_information[:reticulum]
        )

        version_variables = component_information.map do |component, version|
          next nil unless Project.components.include?(component)

          ["OVERRIDE_#{component}_VERSION", version]
        end.compact

        Utils::PipelineHelpers.create_env_file(
          'reticulum_variables',
          version_variables + [['C0_GH_TOKEN', Pyxis::Environment.github_reticulum_publish_token]]
        )
      end

      def remove_build_branch(build_to_promote)
        GitlabClient.client.delete_branch(
          Project::Reticulum.api_gitlab_path,
          "pyxis/canary-build/#{build_to_promote}"
        )
      end

      def publish_tags(coordinator_pipeline_id)
        build_id = GitlabClient.client
                               .list_pipeline_bridges(Project::Pyxis.api_gitlab_path, coordinator_pipeline_id)
                               .find { |bridge| bridge['name'] == 'release-coordinator:canary:build' }
                               .dig('downstream_pipeline', 'id')

        info = ManagedVersioning::ComponentInfo.new(build_id: build_id)
        common = Common.new

        success = common.copy_container_images_to_release_registry(info)

        raise Pyxis::MessageError, 'Failed to copy all container images' unless success
      end
    end
  end
end
