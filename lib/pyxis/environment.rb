# frozen_string_literal: true

module Pyxis
  module Environment
    module_function

    def discord_bot_token
      File.read(ENV.fetch('PYXIS_DC_RELEASE_TOOLS_TOKEN'))
    end

    def github_release_tools_private_key
      File.read(ENV.fetch('PYXIS_GH_RELEASE_TOOLS_PRIVATE_KEY'))
    end

    def github_release_tools_approver_private_key
      File.read(ENV.fetch('PYXIS_GH_RELEASE_TOOLS_APPROVER_PRIVATE_KEY'))
    end

    def github_reticulum_publish_token
      File.read(ENV.fetch('PYXIS_GH_RETICULUM_PUBLISH_TOKEN'))
    end

    def gitlab_release_tools_token
      File.read(ENV.fetch('PYXIS_GL_RELEASE_TOOLS_PRIVATE_TOKEN'))
    end

    def dry_run
      ENV.fetch('DRY_RUN', 'true').downcase
    end
  end
end
