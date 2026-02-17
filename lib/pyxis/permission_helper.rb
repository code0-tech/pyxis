# frozen_string_literal: true

module Pyxis
  PermissionError = Class.new(Pyxis::Error)
  module PermissionHelper
    def checks_active?
      ENV['BYPASS_PERMISSION_CHECKS'].nil?
    end

    def assert_executed_by_schedule!
      return unless checks_active?
      return if ENV['CI_PIPELINE_SOURCE'] == 'schedule'

      raise PermissionError, 'This operation can only be run by a pipeline schedule'
    end

    def assert_executed_by_known_team_member!
      return unless checks_active?
      return unless find_current_user.nil?

      raise PermissionError, 'This operation can only be run by a known team member'
    end

    def find_current_user
      if ENV['GITLAB_USER_LOGIN']
        users.find { |user| user['gitlab'] == ENV['GITLAB_USER_LOGIN'] }
      elsif ENV['DISCORD_USER_ID']
        users.find { |user| user['discord'] == ENV['DISCORD_USER_ID'] }
      else
        raise PermissionError, 'Missing data for permission checks'
      end
    end

    private

    def users
      YAML.safe_load_file(File.absolute_path(File.join(__FILE__, '../../../config/users.yml')))['users']
    end
  end
end
