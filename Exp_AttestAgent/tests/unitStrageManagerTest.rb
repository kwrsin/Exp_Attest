require 'test/unit'

require './challengeFactory'
require './strageManager'
require './constants'

class TC_StrageManager < Test::Unit::TestCase
    def setup
        @path = 'Constants::STORE_PATH'
        # ChallengeFactory.setDumpPath './store/dump'
        @cf = ChallengeFactory.instance
    end

    def teardown
    end

    # def test_mergeFileStrage
    #     uuid = "03b0549efe2941cfa10577561ffebc13"
    #     c = @cf.challenge(uuid)
    #     options = {
    #         challenge: uuid,
    #         path: @path
    #     }
    #     strage = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, options)
    #     result = strage.save!({
    #         counter: 99,
    #         pr_id: 2222,
    #         message: "hello world",
    #     })
    #     strageNew = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, options)
    #     assert_equal(strageNew.prop(:uuid), "03b0549efe2941cfa10577561ffebc13")
    #     assert_equal(strageNew.prop(:create_at), 1606780767)
    #     assert_equal(strageNew.prop(:counter), 99)
    #     assert_equal(strageNew.prop(:pr_id), 2222)
    #     assert_equal(strageNew.prop(:message), "hello world")
    # end

    def test_removeFile
        StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: "94308*",
            path: Constants::STORE_PATH,
        }).remove!
    end

end