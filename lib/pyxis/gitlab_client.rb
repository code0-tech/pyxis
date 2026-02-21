# frozen_string_literal: true

module Pyxis
  class GitlabClient
    include SemanticLogger::Loggable

    GITLAB_URL = 'https://gitlab.com'

    CLIENT_CONFIGS = {
      release_tools: {
        private_token: Pyxis::Environment.gitlab_release_tools_token,
        user_id: 20643824,
      },
    }.freeze

    def self.client(instance = :release_tools)
      CLIENT_CONFIGS[instance][:client] ||= create_client(instance)
    end

    def self.create_client(instance)
      logger.info('Creating gitlab client', instance: instance)

      client_config = CLIENT_CONFIGS[instance]
      options = {
        url: GITLAB_URL,
        headers: {
          'Private-Token': client_config[:private_token],
        },
      }

      faraday = GenericFaraday.create(options)

      GitlabFaraday.new(faraday)
    end

    def self.paginate_json(client, url, options = {})
      response = []

      client.get_json(url, options).tap do |page|
        response += page.body
        while (next_page_link = PageLinks.new(page.response.env.response_headers).next)
          page = client.get_json(next_page_link)
          response += page.body
        end
      end

      response
    end

    class GitlabFaraday
      extend Forwardable

      attr_reader :faraday

      def_delegators :@faraday, :get, :post, :put, :patch, :delete
      def_delegators :@faraday, :get_json, :post_json, :put_json, :patch_json, :delete_json

      def initialize(faraday)
        @faraday = faraday
      end

      # @param project_path_or_id Project path or id to create the branch in
      # @param branch The name of the branch to create
      # @param ref The branch name or commit sha to create the branch from
      def create_branch(project_path_or_id, branch, ref)
        post_json(
          "/api/v4/projects/#{project_path_or_id}/repository/branches",
          {
            branch: branch,
            ref: ref,
          }
        )
      end

      def delete_branch(project_path_or_id, branch)
        delete("/api/v4/projects/#{project_path_or_id}/repository/branches/#{path_encode branch}")
      end

      def create_pipeline(project_path_or_id, ref, variables: nil)
        if variables.is_a?(Hash)
          variables = variables.map do |key, value|
            {
              key: key,
              value: value,
            }
          end
        end

        post_json(
          "/api/v4/projects/#{project_path_or_id}/pipeline",
          {
            ref: ref,
            variables: variables,
          }
        )
      end

      def list_pipeline_bridges(project_path_or_id, pipeline_id)
        paginate_json("/api/v4/projects/#{project_path_or_id}/pipelines/#{pipeline_id}/bridges")
      end

      def path_encode(content)
        content.gsub('/', '%2F')
      end

      def paginate_json(url, options = {})
        GitlabClient.paginate_json(faraday, url, options)
      end
    end

    class PageLinks
      HEADER_LINK = 'link'
      DELIM_LINKS = ','
      LINK_REGEX = /<([^>]+)>; rel="([^"]+)"/
      METAS = %w[last next first prev].freeze

      attr_accessor(*METAS)

      def initialize(headers)
        link_header = headers[HEADER_LINK]

        extract_links(link_header) if link_header && link_header =~ /(next|first|last|prev)/
      end

      private

      def extract_links(header)
        header.split(DELIM_LINKS).each do |link|
          LINK_REGEX.match(link.strip) do |match|
            url = match[1]
            meta = match[2]
            next if !url || !meta || METAS.index(meta).nil?

            send("#{meta}=", url)
          end
        end
      end
    end
  end
end
