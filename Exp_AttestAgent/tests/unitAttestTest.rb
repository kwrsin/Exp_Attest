require 'test/unit'
require './challengeFactory'
require './attestationObjectAnalyzer'

=begin
$ cd Exp_AttestAgent
$ bundle exec ruby tests/unitAttestTest.rb
=end

class TC_Attest < Test::Unit::TestCase
    def setup
        ChallengeFactory.setDumpPath './store/dump'
        @cf = ChallengeFactory.instance
        ENV['ATTEST_APPID'] = 'XXXXXXXXXX.io.github.kwrsin.Exp-Attest'
    end

    def teardown
    end

    def test_analyzer
        uuid = "03b0549efe2941cfa10577561ffebc13"
        c = @cf.challenge(uuid)
        attestationObject = c[:attestation]
        keyId = c[:keyId]

        appId = ENV['ATTEST_APPID'] || ''
        analyzer = AttestationObjectAnalyzer.new(keyId, attestationObject, c[:uuid], appId)
    end
end