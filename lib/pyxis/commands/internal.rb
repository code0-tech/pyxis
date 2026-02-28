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
    end
  end
end
