require 'test/unit'
require './challengeFactory'

=begin
$ cd Exp_AttestAgent
$ bundle exec ruby tests/unitTest.rb
$ bundle exec ruby tests/unitTest.rb --name test_bar
=end

class TC_CF < Test::Unit::TestCase
    def setup
        @cf = ChallengeFactory.instance
    end

    def teardown
    end

    def test_this_is_a_singleton
        assert_equal(@cf, ChallengeFactory.instance)
    end

    def test_new_challenge
        c = @cf.challenge(nil)
        assert_not_nil(c)
        puts @cf.getChallenge
    end

    def test_same_challenge_not_appended
        c = @cf.challenge(nil)

        uid = c['uuid']
        d = @cf.challenge(uid)
        assert_equal(len_c, len_d)
    end
end