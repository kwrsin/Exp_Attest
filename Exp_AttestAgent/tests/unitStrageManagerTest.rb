require 'test/unit'

require './challengeFactory'
require './strageManager'
require './constants'

class TC_StrageManager < Test::Unit::TestCase
    def setup
        @path = Constants::STORE_PATH
        @cf = ChallengeFactory.instance
    end

    def teardown
    end

    def test_mergeFileStrage
        ch = @cf.challenge
        uuid = ch[:uuid]
        ca = ch[:create_at]
        options = {
            challenge: uuid,
            path: @path,
            records: {
                uuid: uuid,
                create_at: ca
            }
        }
        strage = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, options)
        result = strage.save!({
            counter: 99,
            pr_id: 2222,
            message: "hello world",
        })

        options = {
            challenge: uuid,
            path: @path,
        }
        strageNew = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, options)
        assert_equal(strageNew.prop(:uuid), uuid)
        assert_equal(strageNew.prop(:create_at), ca)
        assert_equal(strageNew.prop(:counter), 99)
        assert_equal(strageNew.prop(:pr_id), 2222)
        assert_equal(strageNew.prop(:message), "hello world")
        
        options = {
            challenge: "#{uuid}_*",
            path: @path,
        }
        StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, options).append!({
            counter: 02,
            pr_id: 8080,
            message: "good bye",
        })

        count = Dir.glob(File.join(@path, "#{uuid}*")).count
        assert_equal(3, count)
                
        StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: "#{uuid}*",
            path: Constants::STORE_PATH,
            records: {}
        }).remove!
    end

    def test_removeFile
        File.write(File.join(Constants::STORE_PATH, '94308_Test'), 'test')

        assert_nothing_raised do
            StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
                challenge: "94308*",
                path: Constants::STORE_PATH,
                records: {}
            }).remove!
        end

        assert(FileTest.exist?(File.join(Constants::STORE_PATH, "94308*")) == false, "no file")
    end

end