# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lesli_testing"

# load lesli testing tools
require "lesli_testing/loader"


# register engine for testing
LesliTesting.configure(LesliTesting)


# initialize coverage
LesliTesting.configure_coverage({ :min_coverage => 10 })

require "minitest/autorun"
