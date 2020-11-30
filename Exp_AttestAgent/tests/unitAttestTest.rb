require 'test/unit'
require './challengeFactory'
require './attestationObjectAnalyzer'

=begin
$ cd Exp_AttestAgent
$ bundle exec ruby tests/unitAttestTest.rb
=end

class TC_Attest < Test::Unit::TestCase
    def setup
        @cf = ChallengeFactory.instance
        ENV['ATTEST_APPID'] = 'XXXXXXXXXX.io.github.kwrsin.Exp-Artest'
    end

    def teardown
    end

    def test_analyzer
        uuid = "91ce268c4eac4444a8625b2c24f5626f"
        c = @cf.challenge(uuid)
        attestationObject = c[:attestation]
        keyId = c[:keyId]

        appId = ENV['ATTEST_APPID'] || ''
        analyzer = AttestationObjectAnalyzer.new(keyId, attestationObject, c[:uuid], appId)
    end
end