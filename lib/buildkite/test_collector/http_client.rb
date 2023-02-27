# frozen_string_literal: true

require "net/http"

module Buildkite::TestCollector
  class HTTPClient
    attr :authorization_header
    def initialize(url)
      @url = url
      @authorization_header = "Token token=\"#{Buildkite::TestCollector.api_token}\""
    end

    def post
      contact_uri = URI.parse(url)

      http = Net::HTTP.new(contact_uri.host, contact_uri.port)
      http.use_ssl = contact_uri.scheme == "https"

      contact = Net::HTTP::Post.new(contact_uri.path, {
        "Authorization" => authorization_header,
        "Content-Type" => "application/json",
      })
      contact.body = {
        run_env: Buildkite::TestCollector::CI.env,
        format: "websocket"
      }.to_json

      http.request(contact)
    end

    def post_json(data)
      contact_uri = URI.parse(url)

      http = Net::HTTP.new(contact_uri.host, contact_uri.port)
      http.use_ssl = contact_uri.scheme == "https"

      contact = Net::HTTP::Post.new(contact_uri.path, {
        "Authorization" => authorization_header,
        "Content-Type" => "application/json",
      })

      data_set = data.map(&:as_hash)

      contact.body = {
        run_env: Buildkite::TestCollector::CI.env,
        format: "json",
        data: data_set
      }.to_json

      http.request(contact)
    end

    private

    attr :url
  end
end
