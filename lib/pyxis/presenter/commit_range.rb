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
        "[#{present_sha(current_version)}...#{present_sha(new_version)}](#{compare_link}) (#{commit_amount} commits)"
      end

      private

      def compare_link
        "https://github.com/#{project.github_path}/compare/#{current_version}...#{new_version}"
      end

      def commit_amount
        GithubClient.octokit.compare(project.github_path, current_version, new_version).ahead_by
      end

      def present_sha(sha)
        CommitSha.new(sha).as_short
      end
    end
  end
end
