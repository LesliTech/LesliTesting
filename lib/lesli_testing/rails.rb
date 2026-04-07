
# load lesli testing tools
require_relative "loader"


# register engine for testing
LesliTesting.configure()


# initialize coverage
LesliTesting.configure_coverage({ :min_coverage => 10, :profile => "app" })


# configure tests
LesliTesting.configure_tests()
