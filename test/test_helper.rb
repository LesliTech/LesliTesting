# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)


# load lesli testing tools
require "lesli_testing"


# Keep an explicit project baseline because Rails integration behavior is
# exercised in isolated child processes and is not merged into this process's
# SimpleCov result. Consumer projects retain LesliTesting's 90% default.
LesliTesting.gem("LesliTesting", coverage_min_coverage: 45)


require "minitest/autorun"
