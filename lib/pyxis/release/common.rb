# frozen_string_literal: true

module Pyxis
  module Release
    class Common
      include SemanticLogger::Loggable

      CI_BUILDS_PREFIX = 'ghcr.io/code0-tech/reticulum/ci-builds/'
      CONTAINER_RELEASE_REGISTRY = 'registry.gitlab.com'
      CONTAINER_RELEASE_PREFIX = "#{CONTAINER_RELEASE_REGISTRY}/code0-tech/packages/".freeze

      CONTAINER_RELEASE_PUBLISH_USER = 'code0-release-tools'

      def copy_container_images_to_release_registry(component_info)
        container_tag = info.find_container_tag_for_build_id
        container_tags = component_info.find_manifests.map do |manifest|
          next nil unless Project.components.include?(manifest.first.to_sym)

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
          logger.error('Failed to copy container image to release registry', tag: tag)
          success
        end
      end

      def with_release_registry_auth
        return yield if File.exist?('tmp/gitlab_token')

        logger.info('Authentication with release registry')
        File.write('tmp/gitlab_token', Pyxis::Environment.gitlab_release_tools_token)
        success = system(
          "crane auth login
          -u #{CONTAINER_RELEASE_PUBLISH_USER}
          --password-stdin #{CONTAINER_RELEASE_REGISTRY}
          < tmp/gitlab_token"
        )

        unless success
          logger.error('Failed to authenticate with release registry')
          raise Pyxis::Error, 'Failed to authenticate with release registry'
        end

        yield
      ensure
        system("crane auth logout #{CONTAINER_RELEASE_REGISTRY}")
        File.delete('tmp/gitlab_token')
        logger.info('Unauthenticated from release registry')
      end
    end
  end
end
