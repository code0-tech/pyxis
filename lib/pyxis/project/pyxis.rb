# frozen_string_literal: true

module Pyxis
  module Project
    class Pyxis < Base
      class << self
        def paths
          {
            github: 'code0-tech/pyxis',
            gitlab: 'code0-tech/infrastructure/pyxis',
          }
        end
      end
    end
  end
end
