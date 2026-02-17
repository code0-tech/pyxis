# frozen_string_literal: true

module Pyxis
  module Commands
    class Components < Thor
      include PermissionHelper

      desc 'info', 'Get the component versions for a reticulum build'
      method_option :build, aliases: '-b', desc: 'The build ID', required: true, type: :numeric
      def info
        component_versions = ManagedVersioning::ComponentInfo.new(options[:build]).execute

        raise Pyxis::MessageError, 'This build does not exist' if component_versions.nil?

        result = 'Versions of each component'
        component_versions.each do |component, version|
          result += "\n#{component}: #{version}"
        end
        result
      end

      desc 'build', 'Start a reticulum build with specific versions'
      method_option :aquila_sha, desc: 'Commit SHA of aquila to build', type: :string
      method_option :draco_sha, desc: 'Commit SHA of draco to build', type: :string
      method_option :sagittarius_sha, desc: 'Commit SHA of sagittarius to build', type: :string
      method_option :sculptor_sha, desc: 'Commit SHA of sculptor to build', type: :string
      method_option :taurus_sha, desc: 'Commit SHA of taurus to build', type: :string
      def build
        assert_executed_by_known_team_member!

        version_overrides = {
          aquila: options[:aquila_sha],
          draco: options[:draco_sha],
          sagittarius: options[:sagittarius_sha],
          sculptor: options[:sculptor_sha],
          taurus: options[:taurus_sha],
        }.compact

        pipeline = Pyxis::Services::CreateReticulumBuildService.new(version_overrides).execute

        raise Pyxis::MessageError, 'Failed to create pipeline' if pipeline.nil?

        "Created reticulum build at #{pipeline.web_url}"
      end

      desc 'update', 'Update a component in reticulum'
      method_option :component, aliases: '-c', desc: 'The component to update', required: true, type: :string
      def update
        assert_executed_by_schedule!

        updater(options[:component]).execute
      end

      desc 'list', 'List all available components'
      def list
        result = 'Available components:'
        Pyxis::Project.components.each do |project|
          result += "\n- #{project.downcase}"
        end
        result
      end

      desc 'get_version', 'Get the current version of a component in reticulum'
      method_option :component, aliases: '-c', desc: 'The component to check', required: true, type: :string
      def get_version # rubocop:disable Naming/AccessorMethodName
        current_version = updater(options[:component]).find_current_version
        puts "Current version of #{options[:component]}: #{current_version}"
      end

      no_commands do
        def updater(component)
          component_project_class = Pyxis::Project.const_get(component.capitalize)
          Pyxis::ManagedVersioning::ComponentUpdater.new(component_project_class)
        end
      end
    end
  end
end
