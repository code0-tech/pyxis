# frozen_string_literal: true

module Pyxis
  module Commands
    class Components < Thor
      include PermissionHelper

      desc 'info [BUILD_ID]', 'Get the component versions for a reticulum build'
      def info(build_id)
        component_versions = ManagedVersioning::ComponentInfo.new(build_id).execute

        result = 'Versions of each component'
        component_versions.each do |component, version|
          result += "\n#{component}: #{version}"
        end
        result
      end

      desc 'update [COMPONENT]', 'Update a component in reticulum'
      def update(component)
        assert_executed_by_schedule!

        updater(component).execute
      end

      desc 'list', 'List all available components'
      def list
        result = 'Available components:'
        Pyxis::Project.components.each do |project|
          result += "\n- #{project.downcase}"
        end
        result
      end

      desc 'get_version COMPONENT', 'Get the current version of a component in reticulum'
      def get_version(component)
        current_version = updater(component).find_current_version
        puts "Current version of #{component}: #{current_version}"
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
