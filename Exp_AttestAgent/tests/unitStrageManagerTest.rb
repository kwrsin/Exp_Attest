require 'test/unit'

require './challengeFactory'
require './strageManager'

class TC_StrageManager < Test::Unit::TestCase
    def setup
        @path = './store'
        ChallengeFactory.setDumpPath './store/dump'
        @cf = ChallengeFactory.instance
    end

    def teardown
    end

    # def test_saveFileStrage
    #     uuid = "03b0549efe2941cfa10577561ffebc13"
    #     c = @cf.challenge(uuid)
    #     options = {
    #         challenge: uuid,
    #         path: @path,
    #         records: c
    #     }
    #     strage = StrageManager::Strage.instance().getStrage(:file, options)
    #     strage.save
    # end

    def test_loadFileStrage
        uuid = "03b0549efe2941cfa10577561ffebc13"
        c = @cf.challenge(uuid)
        options = {
            challenge: uuid,
            path: @path
        }
        strage = StrageManager::Strage.instance().getStrage(:file, options)
        strage.output
    end

end