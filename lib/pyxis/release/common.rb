# frozen_string_literal: true

module Pyxis
  module Release
    class Common
      include SemanticLogger::Loggable

      CI_BUILDS_PREFIX = 'ghcr.io/code0-tech/reticulum/ci-builds/'
      CONTAINER_RELEASE_REGISTRY = 'registry.gitlab.com'
      CONTAINER_RELEASE_PREFIX = "#{CONTAINER_RELEASE_REGISTRY}/code0-tech/packages/".freeze

      CONTAINER_RELEASE_PUBLISH_USER = 'code0-release-tools'

      CONTAINER_IMAGES_TO_RELEASE = Project.components + %i[config-generator]

      def copy_container_images_to_release_registry(component_info)
        container_tag = component_info.find_container_tag_for_build_id
        container_tags = component_info.find_manifests.map do |manifest|
          next nil unless CONTAINER_IMAGES_TO_RELEASE.include?(manifest.first.to_sym)

          next "#{manifest.first}:#{container_tag}" if manifest.length == 1

          "#{manifest.first}:#{container_tag}-#{manifest.last}"
        end.compact

        success = true
        container_tags.each do |tag|
          success &&= copy_container_image_to_release_registry(tag)
        end

        success
      end

      def copy_container_image_to_release_registry(tag)
        with_release_registry_auth do
          logger.info('Copying container image to release registry', tag: tag)
          return if Pyxis::GlobalStatus.dry_run?

          success = system("crane copy #{CI_BUILDS_PREFIX}#{tag} #{CONTAINER_RELEASE_PREFIX}#{tag}")
          logger.error('Failed to copy container image to release registry', tag: tag) unless success
          success
        end
      end

      def with_release_registry_auth
        token_exists = File.exist?('tmp/gitlab_token')
        return yield if token_exists

        logger.info('Authentication with release registry')
        File.write('tmp/gitlab_token', Pyxis::Environment.gitlab_release_tools_token)
        success = system(
          'crane auth login ' \
          "-u #{CONTAINER_RELEASE_PUBLISH_USER} " \
          "--password-stdin #{CONTAINER_RELEASE_REGISTRY} " \
          '< tmp/gitlab_token'
        )

        unless success
          logger.error('Failed to authenticate with release registry')
          raise Pyxis::Error, 'Failed to authenticate with release registry'
        end

        yield
      ensure
        unless token_exists
          system("crane auth logout #{CONTAINER_RELEASE_REGISTRY}")
          File.delete('tmp/gitlab_token')
          logger.info('Unauthenticated from release registry')
        end
      end

      def publish_github_release(component_info, prerelease:)
        logger.info('Starting release to codezero repository', tag: component_info.find_container_tag_for_build_id)

        release_version = component_info.find_container_tag_for_build_id
        reticulum_sha = component_info.execute(filter_components: [:reticulum])[:reticulum]

        compose_path = 'docker-compose/docker-compose.yml'
        env_path = 'docker-compose/.env'

        codezero_compose_content = GithubClient.octokit.contents(
          Project::Codezero.github_path,
          path: compose_path
        )
        codezero_env_content = GithubClient.octokit.contents(
          Project::Codezero.github_path,
          path: env_path
        )

        reticulum_compose_content = GithubClient.octokit.contents(
          Project::Reticulum.github_path,
          path: compose_path,
          ref: reticulum_sha
        )
        reticulum_env_content = GithubClient.octokit.contents(
          Project::Reticulum.github_path,
          path: env_path,
          ref: reticulum_sha
        )

        reticulum_env = Base64.decode64 reticulum_env_content.content
        reticulum_compose = Base64.decode64 reticulum_compose_content.content

        codezero_env = reticulum_env.sub('IMAGE_TAG=', "IMAGE_TAG=#{release_version}")

        GithubClient.octokit.update_contents(
          Project::Codezero.github_path,
          env_path,
          "Update compose env for #{release_version}",
          codezero_env_content.sha,
          codezero_env,
          Project::Codezero.default_branch
        )
        GithubClient.octokit.update_contents(
          Project::Codezero.github_path,
          compose_path,
          "Update compose file for #{release_version}",
          codezero_compose_content.sha,
          reticulum_compose,
          Project::Codezero.default_branch
        )

        GithubClient.octokit.create_release(
          Project::Codezero.github_path,
          release_version,
          name: release_version,
          prerelease: prerelease
        )
      end
    end
  end
end
