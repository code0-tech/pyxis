# frozen_string_literal: true

module Pyxis
  module Checks
    class TucanaVersionMatch
      include Check

      attr_reader :component_info

      def initialize(component_info)
        @component_info = component_info
      end

      def perform_check!
        [sagittarius_version, aquila_version, draco_version, taurus_version].uniq.size == 1
      end

      def status_message
        return "#{icon} Components use the same tucana version" if pass?

        message = []
        message << "#{icon} Components use different tucana versions"
        message << ''
        message << "sagittarius: #{sagittarius_version}"
        message << "aquila: #{aquila_version}"
        message << "draco: #{draco_version}"
        message << "taurus: #{taurus_version}"

        message.join("\n")
      end

      private

      def sagittarius_version
        return @sagittarius_version if defined?(@sagittarius_version)

        gemfile_content = Base64.decode64 GithubClient.octokit.contents(
          Project::Sagittarius.github_path,
          path: 'Gemfile.lock',
          ref: executed_component_info[:sagittarius]
        ).content

        @sagittarius_version = Bundler::LockfileParser.new(gemfile_content)
                                                      .specs
                                                      .find { |spec| spec.name == 'tucana' }
                                                      .version
                                                      .to_s
      end

      def aquila_version
        @aquila_version ||= from_cargo_lockfile(
          Base64.decode64(
            GithubClient.octokit.contents(
              Project::Aquila.github_path,
              path: 'Cargo.lock',
              ref: executed_component_info[:aquila]
            ).content
          )
        )
      end

      def draco_version
        @draco_version ||= from_cargo_lockfile(
          Base64.decode64(
            GithubClient.octokit.contents(
              Project::Draco.github_path,
              path: 'Cargo.lock',
              ref: executed_component_info[:draco]
            ).content
          )
        )
      end

      def taurus_version
        @taurus_version ||= from_cargo_lockfile(
          Base64.decode64(
            GithubClient.octokit.contents(
              Project::Taurus.github_path,
              path: 'Cargo.lock',
              ref: executed_component_info[:taurus]
            ).content
          )
        )
      end

      def from_cargo_lockfile(lockfile)
        toml = TomlRB.parse(lockfile, symbolize_keys: true)
        toml[:package].find { |package| package[:name] == 'tucana' }[:version]
      end

      def executed_component_info
        @executed_component_info ||= component_info.execute
      end
    end
  end
end
