# frozen_string_literal: true

module Pyxis
  class Cli < Thor
    desc 'components', 'Commands managing projects under managed versioning'
    subcommand 'components', Pyxis::Commands::Components

    desc 'release', 'Commands managing the release process'
    subcommand 'release', Pyxis::Commands::Release

    desc 'internal', 'Internal commands for usage by the pipeline', hide: true
    subcommand 'internal', Pyxis::Commands::Internal

    def Thor.exit_on_failure?
      true
    end
  end
end
