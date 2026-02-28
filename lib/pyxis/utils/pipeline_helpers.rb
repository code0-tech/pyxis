# frozen_string_literal: true

module Pyxis
  module Utils
    module PipelineHelpers
      module_function

      def create_env_file(name, variables)
        path = File.absolute_path(File.join(__FILE__, "../../../../tmp/#{name}.env"))
        File.write(path, variables.map { |k, v| "#{k}=#{v}" }.join("\n"))
      end
    end
  end
end
