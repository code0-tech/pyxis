# frozen_string_literal: true

module Pyxis
  module Project
    class Velorum < Base
      class << self
        def paths
          {
            github: 'code0-tech/velorum',
            gitlab: 'code0-tech/development/velorum',
          }
        end
      end
    end
  end
end
