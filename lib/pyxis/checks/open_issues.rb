# frozen_string_literal: true

module Pyxis
  module Checks
    class OpenIssues
      include Check

      attr_reader :check_context, :labels

      def initialize(check_context, labels)
        @check_context = check_context
        @labels = labels
      end

      def perform_check!
        issues.empty?
      end

      def status_message
        return "#{icon} No open #{check_context} issues" if pass?

        message = []
        message << "#{icon} Open #{check_context} issues"
        issues.each do |issue|
          message << "- [#{issue.title}](#{issue.html_url})"
        end

        message.join("\n")
      end

      private

      def issues
        @issues ||= GithubClient.octokit.search_issues(
          "org:#{GithubClient::ORGANIZATION_NAME} is:open is:issue #{labels.map { |l| "label:#{l}" }.join(' ')}"
        ).items
      end
    end
  end
end
