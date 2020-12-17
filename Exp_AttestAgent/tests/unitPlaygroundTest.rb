require 'test/unit'

class TC_Playground < Test::Unit::TestCase
    def setup
    end

    def teardown
    end


    def test_error_handling
        begin
            raise 'abcde'
        rescue
            puts $!
        end
    end
end