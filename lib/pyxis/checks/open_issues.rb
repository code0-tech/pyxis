# frozen_string_literal: true

module Pyxis
  module Checks
    class OpenIssues
      include Check

      Issue = Struct.new(:title, :html_url)

      PAGE_SIZE = 100

      attr_reader :check_context, :field, :values

      def initialize(check_context, field:, values:)
        @check_context = check_context
        @field = field
        @values = values
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
        @issues ||= values
                    .flat_map { |value| fetch_issues_for(value) }
                    .uniq(&:html_url)
      end

      def fetch_issues_for(value)
        issues = []
        after = nil

        loop do
          page = fetch_page(value, after)
          repositories = page&.dig(:nodes) || []

          repositories.each do |repository|
            (repository.dig(:issues, :nodes) || []).each do |issue|
              issues << Issue.new(issue[:title], issue[:url])
            end
          end

          page_info = page&.dig(:pageInfo) || {}
          break unless page_info[:hasNextPage]

          after = page_info[:endCursor]
        end

        issues
      end

      def fetch_page(value, after)
        response = Pyxis::GlobalStatus.with_faraday_dry_run_bypass do
          variables = { org: GithubClient::ORGANIZATION_NAME, field: field, value: value, after: after }
          GithubClient.octokit.post(
            '/graphql',
            { query: issues_query, variables: variables }.to_json
          )
        end

        response.dig(:data, :organization, :repositories)
      end

      def issues_query
        <<~GRAPHQL
          query ($org: String!, $field: String!, $value: String!, $after: String) {
            organization(login: $org) {
              repositories(first: #{PAGE_SIZE}, after: $after) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                nodes {
                  issues(
                    first: #{PAGE_SIZE},
                    states: OPEN,
                    filterBy: { issueFieldValues: [{ fieldName: $field, multiSelectOptionValues: [$value] }] }
                  ) {
                    nodes {
                      title
                      url
                    }
                  }
                }
              }
            }
          }
        GRAPHQL
      end
    end
  end
end
