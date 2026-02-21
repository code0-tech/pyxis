# frozen_string_literal: true

module Pyxis
  module Commands
    class Internal < Thor
      include Thor::Actions

      RETICULUM_CI_BUILDS_PREFIX = 'ghcr.io/code0-tech/reticulum/ci-builds/'
      CONTAINER_RELEASE_PREFIX = 'registry.gitlab.com/code0-tech/packages/'

      desc 'release_canary_tmp_branch', ''
      method_option :build_id_to_promote, required: true, type: :numeric
      def release_canary_tmp_branch
        component_information = Pyxis::ManagedVersioning::ComponentInfo.new(
          build_id: options[:build_id_to_promote]
        ).execute

        raise 'Build not found' if component_information.nil?

        GitlabClient.client.create_branch(
          Project::Reticulum.api_gitlab_path,
          "pyxis/canary-build/#{options[:build_id_to_promote]}",
          component_information[:reticulum]
        )

        version_variables = component_information.map do |component, version|
          next nil unless Project.components.include?(component)

          ["OVERRIDE_#{component}_VERSION", version]
        end.compact

        create_env_file(
          'reticulum_variables',
          version_variables + [['C0_GH_TOKEN', Pyxis::Environment.github_reticulum_publish_token]]
        )
      end

      desc 'release_canary_tmp_branch_cleanup', ''
      method_option :build_id_to_promote, required: true, type: :numeric
      def release_canary_tmp_branch_cleanup
        GitlabClient.client.delete_branch(
          Project::Reticulum.api_gitlab_path,
          "pyxis/canary-build/#{options[:build_id_to_promote]}"
        )
      end

      desc 'release_canary_publish_tags', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def release_canary_publish_tags
        build_id = GitlabClient.client
                               .list_pipeline_bridges(Project::Pyxis.api_gitlab_path, options[:coordinator_pipeline_id])
                               .find { |bridge| bridge['name'] == 'release-coordinator:canary:build' }
                               .dig('downstream_pipeline', 'id')

        info = ManagedVersioning::ComponentInfo.new(build_id: build_id)
        container_tag = info.find_container_tag_for_build_id
        container_tags = info.find_manifests.map do |manifest|
          next nil unless Project.components.include?(manifest.first.to_sym)

          next "#{manifest.first}:#{container_tag}" if manifest.length == 1

          "#{manifest.first}:#{container_tag}-#{manifest.last}"
        end.compact

        File.write('tmp/gitlab_token', Pyxis::Environment.gitlab_release_tools_token)
        run 'crane auth login -u code0-release-tools --password-stdin registry.gitlab.com < tmp/gitlab_token'

        overall_success = true

        original_pretend = options[:pretend]
        options[:pretend] = Pyxis::GlobalStatus.dry_run?
        container_tags.each do |tag|
          success = run "crane copy #{RETICULUM_CI_BUILDS_PREFIX}#{tag} #{CONTAINER_RELEASE_PREFIX}#{tag}",
                        abort_on_failure: false
          overall_success &&= success

          logger.error('Failed to copy container image to release registry', image: tag) unless success
        end
        options[:pretend] = original_pretend

        run 'crane auth logout registry.gitlab.com'
        File.delete('tmp/gitlab_token')

        abort unless overall_success || Pyxis::GlobalStatus.dry_run?
      end

      no_commands do
        include SemanticLogger::Loggable

        def create_env_file(name, variables)
          path = File.absolute_path(File.join(__FILE__, "../../../../tmp/#{name}.env"))
          File.write(path, variables.map { |k, v| "#{k}=#{v}" }.join("\n"))
        end
      end
    end
  end
end
