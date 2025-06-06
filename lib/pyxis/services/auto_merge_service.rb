# frozen_string_literal: true

module Pyxis
  module Services
    class AutoMergeService
      include ::SemanticLogger::Loggable

      attr_reader :project, :pull_request

      def initialize(project, pull_request)
        @project = project
        @pull_request = pull_request
      end

      def execute
        logger.info('Starting auto merge', project: project.component_name, pull_request: pull_request.number)

        ApprovePrService.new(project, pull_request).execute

        begin
          GithubClient.octokit.merge_pull_request(project.github_path, pull_request.number)
        rescue Octokit::MethodNotAllowed
          response = GithubClient.octokit.post(
            '/graphql',
            { query: enable_auto_merge_mutation, variables: { pullRequestId: pull_request.node_id } }.to_json
          )

          if response.key?(:errors) && response[:errors].any?
            logger.warn('Errors while enabling auto merge', error: response[:errors])
          end
        end
      end

      private

      def enable_auto_merge_mutation
        <<~GRAPHQL
          mutation ($pullRequestId: ID!) {
            enablePullRequestAutoMerge(input: { pullRequestId: $pullRequestId }) {
              pullRequest {
                autoMergeRequest {
                  enabledAt
                  enabledBy { login }
                }
              }
            }
          }
        GRAPHQL
      end
    end
  end
end
