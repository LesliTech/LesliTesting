# frozen_string_literal: true

require_relative "test_helper"
require "lesli_testing/helpers/response_integration_helper"

class ResponseIntegrationHelperTest < Minitest::Test
    include LesliTesting::ResponseIntegrationHelper

    attr_accessor :response

    Response = Struct.new(:status, :media_type, :content_type, :body) do
        def successful?
            status.between?(200, 299)
        end
    end

    Body = Class.new(String) do
        def blank?
            empty?
        end
    end

    def test_successful_response_compares_the_media_type_without_the_charset
        self.response = Response.new(
            200,
            "application/json",
            "application/json; charset=iso-8859-1"
        )

        expect_response_with_successful
    end

    def test_response_json_uses_the_public_response_accessor
        self.response = Response.new(
            200,
            "application/json",
            nil,
            Body.new('{"status":"ok"}')
        )

        assert_equal({ "status" => "ok" }, response_json)
    end

    def test_helpers_accept_an_explicit_response
        self.response = Response.new(
            500,
            "text/plain",
            nil,
            Body.new("default")
        )
        explicit_response = Response.new(
            201,
            "application/json",
            "application/json; charset=utf-8",
            Body.new('{"source":"explicit"}')
        )

        assert_equal({ "source" => "explicit" }, response_json(explicit_response))
        assert_successful_json_response(explicit_response)
    end
end
