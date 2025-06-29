# frozen_string_literal: true

module Pyxis
  module ManagedVersioning
    class ComponentUpdater
      include ::SemanticLogger::Loggable

      attr_reader :component

      def initialize(component)
        @component = component
      end

      def execute
        logger.tagged(component_updater: component.component_name) do
          logger.info('Running component updater')

          if update_branch_exists?
            logger.warn('Update branch already exists, skipping', branch: update_branch)
            return
          end

          current_version = find_current_version
          new_version = find_newest_version

          if current_version == new_version || new_version.nil?
            logger.info('Component already up to date', current_version: current_version, new_version: new_version)
            return
          end

          logger.info('Updating component version', current_version: current_version, new_version: new_version)

          unless Pyxis::GlobalStatus.dry_run?
            GithubClient.octokit.create_ref(
              Project::Reticulum.github_path,
              "refs/heads/#{update_branch}",
              GithubClient.octokit.branch(Project::Reticulum.github_path, Project::Reticulum.default_branch).commit.sha
            )

            GithubClient.octokit.update_contents(
              Project::Reticulum.github_path,
              version_file,
              "Update #{component.component_name} version to #{new_version[0...11]}",
              version_file_content.sha,
              new_version,
              branch: update_branch
            )

            new_version_link = "[#{new_version[0...11]}](https://github.com/#{component.github_path}/commits/#{new_version})"
            compare_link = "[Compare changes](https://github.com/#{component.github_path}/compare/#{current_version}...#{new_version})"
            pr = GithubClient.octokit.create_pull_request(
              Project::Reticulum.github_path,
              Project::Reticulum.default_branch,
              update_branch,
              "Update #{component.component_name} version to #{new_version[0...11]}",
              <<~DESCRIPTION
              Update #{component.component_name} to #{new_version_link} as part of managed versioning

              #{compare_link}
              DESCRIPTION
            )
            logger.info('Created pull request', pull_request_url: pr.html_url)

            Pyxis::Services::AutoMergeService.new(Project::Reticulum, pr).execute
          end

          logger.info('Finished component updater', current_version: current_version, new_version: new_version)
        end
      end

      def find_current_version
        Base64.decode64 version_file_content.content
      end

      def find_newest_version
        filter_for_passing_checks(new_commits).first
      end

      def version_file
        "versions/#{component.component_name}"
      end

      def update_branch
        "pyxis/update/#{component.component_name}"
      end

      private

      def update_branch_exists?
        GithubClient.octokit.branch(Project::Reticulum.github_path, update_branch).name == update_branch
      rescue Octokit::NotFound
        false
      end

      def version_file_content
        @version_file_content ||= GithubClient.octokit.contents(Project::Reticulum.github_path, path: version_file)
      end

      def new_commits
        commits = GithubClient.octokit
                              .compare(component.github_path, find_current_version, component.default_branch)
                              .commits
                              .map(&:sha)
                              .reverse

        logger.debug('Found new commits', commits: commits)

        commits
      end

      def filter_for_passing_checks(commits)
        filtered_commits = commits.filter do |commit|
          conclusions = GithubClient.octokit
                                    .check_runs_for_ref(component.github_path, commit)
                                    .check_runs
                                    .map(&:conclusion)
          !conclusions.empty? && conclusions.all? { |conclusion| conclusion == 'success' }
        end

        logger.debug('Filtered commits for passing checks', commits: filtered_commits)

        filtered_commits
      end
    end
  end
end
