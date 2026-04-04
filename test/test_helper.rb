# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lesli_testing"

require "lesli_testing/loader"

# Start Lesli testing coverage
LesliTesting.configure(LesliTesting, { :min_coverage => 10 })

require "minitest/autorun"
