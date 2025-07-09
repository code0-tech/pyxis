# frozen_string_literal: true

module Pyxis
  module Presenter
    class CommitRange
      attr_reader :project, :current_version, :new_version

      def initialize(project, current_version, new_version)
        @project = project
        @current_version = current_version
        @new_version = new_version
      end

      def as_markdown
        "[#{current_version[0...11]}...#{new_version[0...11]}](#{compare_link}) (#{commit_amount} commits)"
      end

      private

      def compare_link
        "https://github.com/#{project.github_path}/compare/#{current_version}...#{new_version}"
      end

      def commit_amount
        GithubClient.octokit.compare(project.github_path, current_version, new_version).ahead_by
      end
    end
  end
end
