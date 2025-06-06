# frozen_string_literal: true

require 'bundler'
Bundler.require

module Pyxis
end

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load_namespace(Pyxis::Logger)
loader.eager_load_namespace(Pyxis::DryRunEnforcer)
