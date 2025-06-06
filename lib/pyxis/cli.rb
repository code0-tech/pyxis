# frozen_string_literal: true

module Pyxis
  class Cli < Thor
    desc 'components', 'Commands managing projects under managed versioning'
    subcommand 'components', Pyxis::Commands::Components

    def self.exit_on_failure?
      true
    end
  end
end
