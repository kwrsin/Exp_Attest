require 'test/unit'
require './constants'
require './assertionObjectAnalyzer'

=begin
$ cd Exp_AssertAgent
$ bundle exec ruby tests/unitAssertTest.rb
=end

class TC_Attest < Test::Unit::TestCase
    def setup
        data = File.read('../store/assert_param')
        @params = Marshal.load(data)
    end

    def teardown
    end

    def test_analyzer
        appId = ENV['ATTEST_APPID'] || ''
        analyzer = AssertionObjectAnalyzer.new(@params[:clientData], @params[:assertion], appId)
        analyzer.verify!
    end
end