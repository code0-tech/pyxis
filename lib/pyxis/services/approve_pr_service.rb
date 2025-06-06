# frozen_string_literal: true

module Pyxis
  module Services
    class ApprovePrService
      include ::SemanticLogger::Loggable

      attr_reader :project, :pull_request

      def initialize(project, pull_request)
        @project = project
        @pull_request = pull_request
      end

      def execute
        logger.info('Approving PR', project: project.component_name, pull_request: pull_request.number)

        return if Pyxis::GlobalStatus.dry_run?

        GithubClient.octokit(:release_tools_approver).create_pull_request_review(
          project.github_path,
          pull_request.number,
          { event: 'APPROVE' }
        )
      end
    end
  end
end
