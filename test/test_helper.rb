# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)


# load lesli testing tools
require "lesli_testing"


# register engine for testing
LesliTesting.gem("LesliTesting")


require "minitest/autorun"
