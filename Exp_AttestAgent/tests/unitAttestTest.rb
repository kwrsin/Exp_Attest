require 'test/unit'
require './constants'
require './challengeFactory'
require './attestationObjectAnalyzer'
require './strageManager'

=begin
$ cd Exp_AttestAgent
$ bundle exec ruby tests/unitAttestTest.rb
=end

class TC_Attest < Test::Unit::TestCase
    def setup
        @path = './store'
        ChallengeFactory.setDumpPath @path 
        @cf = ChallengeFactory.instance
        ENV['ATTEST_APPID'] = Constants::APPLE_APPID
    end

    def teardown
    end

    # def test_analyzer
    #     uuid = "03b0549efe2941cfa10577561ffebc13"
    #     c = @cf.challenge(uuid)
    #     attestationObject = c[:attestation]
    #     keyId = c[:keyId]

    #     appId = ENV['ATTEST_APPID'] || ''
    #     analyzer = AttestationObjectAnalyzer.new(keyId, attestationObject, c[:uuid], appId)
    #     begin
    #         mode = analyzer.verify!
    #         puts mode
    #     rescue => error
    #         puts error.message
    #     end
    # end

    def test_attestedObject
        uuid = "03b0549efe2941cfa10577561ffebc13"
        c = @cf.challenge(uuid)
        attestationObject = c[:attestation]
        keyId = c[:keyId]

        appId = ENV['ATTEST_APPID'] || ''
        analyzer = AttestationObjectAnalyzer.new(keyId, attestationObject, c[:uuid], appId)
        records = analyzer.toAttestedObject!
        options = {
            challenge: uuid,
            path: @path,
            records: records
        }
        strage = StrageManager::Strage.instance().getStrage(:file, options)
        strage.save!

    end
end