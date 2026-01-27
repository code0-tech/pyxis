# frozen_string_literal: true

require 'bundler'

ENV['DISCORDRB_NONACL'] = 'true' # disable warning that libsodium is not available
Bundler.require

module Pyxis
  Error = Class.new(StandardError)
  MessageError = Class.new(Pyxis::Error)
end

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load_namespace(Pyxis::Logger)
loader.eager_load_namespace(Pyxis::DryRunEnforcer)
loader.eager_load_namespace(Pyxis::Project::Base)
