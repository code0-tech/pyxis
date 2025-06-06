# frozen_string_literal: true

module Pyxis
  module Project
    class Aquila < Base
      class << self
        def paths
          {
            github: 'code0-tech/aquila',
            gitlab: 'code0-tech/development/aquila',
          }
        end
      end
    end
  end
end
