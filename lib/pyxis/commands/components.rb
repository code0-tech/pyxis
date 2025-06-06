# frozen_string_literal: true

module Pyxis
  module Commands
    class Components < Thor
      desc 'update COMPONENT', 'Update a component in reticulum'
      def update(component)
        updater(component).execute
      end

      desc 'list', 'List all available components'
      def list
        puts 'Available components:'
        Pyxis::Project.constants.each do |project|
          next if project == :Base

          puts "- #{project.downcase}"
        end
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
