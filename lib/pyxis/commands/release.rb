# frozen_string_literal: true

module Pyxis
  module Commands
    class Release < Thor
      include SemanticLogger::Loggable
      include PermissionHelper

      desc 'create_canary', 'Promote an experimental build to canary'
      exclusive do
        at_least_one do
          method_option :build_id,
                        aliases: '-b',
                        desc: 'The build ID',
                        required: false,
                        type: :numeric
          method_option :container_tag,
                        aliases: '-c',
                        desc: 'The container tag excluding variant modifiers',
                        required: false,
                        type: :string
        end
      end
      def create_canary
        assert_executed_by_delivery_team_member!

        info = ManagedVersioning::ComponentInfo.new(
          build_id: options[:build_id],
          container_tag: options[:container_tag]
        )

        raise Pyxis::MessageError, 'This build does not exist' if info.find_build_id_for_container_tag.nil?
        raise Pyxis::MessageError, 'This build does not exist' if info.find_container_tag_for_build_id.nil?

        pipeline = GitlabClient.client.create_pipeline(
          Project::Pyxis.api_gitlab_path,
          Project::Pyxis.default_branch,
          variables: {
            PIPELINE_NAME: "Release #{info.find_container_tag_for_build_id} as canary",
            RELEASE_COORDINATOR: 'canary',
            BUILD_ID_TO_PROMOTE: info.find_build_id_for_container_tag.to_s,
          }
        )

        if pipeline.response.status != 201
          logger.warn('Failed to create pipeline for canary release', response: response.body)
          raise Pyxis::MessageError, 'Failed to create pipeline'
        end

        "Created coordinator pipeline at #{pipeline.body.web_url}"
      end
    end
  end
end
