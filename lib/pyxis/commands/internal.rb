# frozen_string_literal: true

module Pyxis
  module Commands
    class Internal < Thor
      include Thor::Actions

      desc 'release_canary_tmp_branch', ''
      method_option :build_id_to_promote, required: true, type: :numeric
      def release_canary_tmp_branch
        Pyxis::Release::Canary.new.create_build_branch(options[:build_id_to_promote])
      end

      desc 'release_canary_tmp_branch_cleanup', ''
      method_option :build_id_to_promote, required: true, type: :numeric
      def release_canary_tmp_branch_cleanup
        Pyxis::Release::Canary.new.remove_build_branch(options[:build_id_to_promote])
      end

      desc 'release_canary_publish_tags', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def release_canary_publish_tags
        Pyxis::Release::Canary.new.publish_tags(options[:coordinator_pipeline_id])
      end

      desc 'release_canary_publish_release', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def release_canary_publish_release
        Pyxis::Release::Canary.new.publish_release(options[:coordinator_pipeline_id])
      end

      desc 'release_notify_publish_pending', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def release_notify_publish_pending
        pipeline = GitlabClient.client.get_pipeline(
          Project::Pyxis.api_gitlab_path,
          options[:coordinator_pipeline_id]
        ).body
        raise 'Pipeline not found' if pipeline.nil?

        Pyxis::DiscordClient.new.send_notification(<<~DESC, :warn)
          Coordinator pipeline awaiting approval for release publishing
          #{"> #{pipeline.name}" if pipeline.name}
          #{pipeline.web_url}
        DESC
      end

      desc 'notify_new_coordinator', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def notify_new_coordinator
        pipeline = GitlabClient.client.get_pipeline(
          Project::Pyxis.api_gitlab_path,
          options[:coordinator_pipeline_id]
        ).body
        raise 'Pipeline not found' if pipeline.nil?

        Pyxis::DiscordClient.new.send_notification(<<~DESC)
          New coordinator pipeline started
          #{"> #{pipeline.name}" if pipeline.name}
          #{pipeline.web_url}
        DESC
      end

      desc 'notify_finish_coordinator', ''
      method_option :coordinator_pipeline_id, required: true, type: :numeric
      def notify_finish_coordinator
        pipeline = GitlabClient.client.get_pipeline(
          Project::Pyxis.api_gitlab_path,
          options[:coordinator_pipeline_id]
        ).body
        raise 'Pipeline not found' if pipeline.nil?

        Pyxis::DiscordClient.new.send_notification(<<~DESC)
          Coordinator pipeline has finished
          #{"> #{pipeline.name}" if pipeline.name}
          #{pipeline.web_url}
        DESC
      end

      desc 'check_canary_release', ''
      method_option :build_id_to_promote, required: true, type: :numeric
      def check_canary_release
        check = Pyxis::Checks::CanaryRelease.new(options[:build_id_to_promote])

        severity = check.pass? ? :info : :error

        Pyxis::DiscordClient.new.send_notification(check.status_message, severity)

        puts check.status_message

        exit(false) unless check.pass?
      end
    end
  end
end
