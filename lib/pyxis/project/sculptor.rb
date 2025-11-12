# frozen_string_literal: true

module Pyxis
  module Project
    class Sculptor < Base
      class << self
        def paths
          {
            github: 'code0-tech/sculptor',
            gitlab: 'code0-tech/development/sculptor',
          }
        end
      end
    end
  end
end
