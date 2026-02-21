# frozen_string_literal: true

module Pyxis
  module Commands
    class Release < Thor
      include PermissionHelper

      desc 'create_canary', 'Promote an experimental build to canary'
      exclusive do
        at_least_one do
          method_option :build,
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

        build_id = options[:build] || ManagedVersioning::ComponentInfo.new(
          container_tag: options[:container_tag]
        ).find_build_id_for_container_tag

        raise Pyxis::MessageError, 'This build does not exist' if build_id.nil?

        pipeline = GitlabClient.client.create_pipeline(
          Project::Pyxis.api_gitlab_path,
          Project::Pyxis.default_branch,
          variables: {
            RELEASE_COORDINATOR: 'canary',
            BUILD_ID_TO_PROMOTE: build_id.to_s,
          }
        )

        raise Pyxis::MessageError, 'Failed to create pipeline' if pipeline.response.status != 201

        "Created coordinator pipeline at #{pipeline.body.web_url}"
      end
    end
  end
end
