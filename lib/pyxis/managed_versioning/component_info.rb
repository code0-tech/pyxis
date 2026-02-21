# frozen_string_literal: true

module Pyxis
  module ManagedVersioning
    class ComponentInfo
      include SemanticLogger::Loggable

      attr_reader :build_id, :container_tag

      def initialize(build_id: nil, container_tag: nil)
        @build_id = build_id
        @container_tag = container_tag
      end

      # @return [Hash<Symbol, String>] The versions of each component in the build
      # @return [nil] If the build does not exist
      def execute
        @build_id = find_build_id_for_container_tag unless container_tag.nil?

        return nil if build_id.nil?

        pipeline, jobs = load_pipeline(build_id)

        return nil if jobs.nil?

        container_version = find_container_version(jobs)

        manifests = find_manifests_from_jobs(jobs)

        components = {
          reticulum: pipeline.body.sha,
        }

        manifests.each do |image|
          component = image.first.to_sym
          next if components.key?(component)

          image_tag = image.length == 1 ? container_version : "#{container_version}-#{image.last}"

          components[component] = annotation_for(
            "code0-tech/reticulum/ci-builds/#{component}",
            image_tag,
            'org.opencontainers.image.version'
          )
        end

        components.compact
      end

      def find_build_id_for_container_tag
        annotation_for(
          'code0-tech/reticulum/ci-builds/mise',
          container_tag,
          'tech.code0.reticulum.pipeline.id'
        )
      end

      def find_container_tag_for_build_id
        _, jobs = load_pipeline(build_id)
        return nil if jobs.nil?

        find_container_version(jobs)
      end

      def find_manifests
        _, jobs = load_pipeline(build_id)
        return nil if jobs.nil?

        find_manifests_from_jobs(jobs)
      end

      private

      def ghcr_client
        @ghcr_client ||= GenericFaraday.create({ url: 'https://ghcr.io' })
      end

      def token_for(image)
        response = ghcr_client.get_json(
          'token',
          {
            scope: "repository:#{image}:pull",
            service: 'ghcr.io',
          }
        )

        logger.warn('Failed to retrieve token', image: image) unless response.response.status == 200

        response.body.token
      end

      def annotation_for(image, tag, annotation)
        token = token_for(image)

        response = ghcr_client.get_json(
          "v2/#{image}/manifests/#{tag}",
          {},
          {
            Authorization: "Bearer #{token}",
            Accept: 'application/vnd.oci.image.index.v1+json',
          }
        )

        logger.warn('Failed to retrieve tag for image', image: image, tag: tag) unless response.response.status == 200

        response.body.annotations&.[](annotation)
      end

      def find_manifests_from_jobs(jobs)
        jobs.map { |job| job['name'] }
            .select { |job| job.start_with?('manifest:') }
            .map { |job| job.delete_prefix('manifest:') }
            .sort
            .map { |job| job.split(': ') }
            .map do |image|
          next image if image.length == 1

          [image.first, image.last.delete_prefix('[').delete_suffix(']')]
        end
      end

      def find_container_version(jobs)
        job = jobs.find { |job| job['name'] == 'generate-environment' }
        return build_id if job.nil? # fallback to build_id if job not found

        trace = GitlabClient.client.get(
          "/api/v4/projects/#{Project::Reticulum.api_gitlab_path}/jobs/#{job['id']}/trace"
        )
        trace.body
             .lines
             .drop_while { |line| line !~ /\e\[0Ksection_start:\d+:glpa_summary/ }
             .drop(1)
             .take_while { |line| line !~ /\e\[0Ksection_end:\d+:glpa_summary/ }
             .find { |line| line =~ /RETICULUM_CONTAINER_VERSION=[0-9a-zA-Z\-.]+$/ }
             .split('=')[1].chomp
      end

      def load_pipeline(pipeline_id)
        pipeline = GitlabClient.client.get_json(
          "/api/v4/projects/#{Project::Reticulum.api_gitlab_path}/pipelines/#{pipeline_id}"
        )
        return nil if pipeline.response.status == 404

        [
          pipeline,
          GitlabClient.paginate_json(
            GitlabClient.client,
            "/api/v4/projects/#{Project::Reticulum.api_gitlab_path}/pipelines/#{pipeline_id}/jobs"
          )
        ]
      end
    end
  end
end
