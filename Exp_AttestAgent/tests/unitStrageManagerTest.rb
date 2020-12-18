require 'test/unit'

require './challengeFactory'
require './storageManager'
require './constants'

class TC_StorageManager < Test::Unit::TestCase
    def setup
        @path = Constants::STORE_PATH
        @cf = ChallengeFactory.instance
    end

    def teardown
    end

    def test_mergeFileStorage
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
        storage = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, options)
        result = storage.save!({
            counter: 99,
            pr_id: 2222,
            message: "hello world",
        })

        options = {
            challenge: uuid,
            path: @path,
        }
        storageNew = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, options)
        assert_equal(storageNew.prop(:uuid), uuid)
        assert_equal(storageNew.prop(:create_at), ca)
        assert_equal(storageNew.prop(:counter), 99)
        assert_equal(storageNew.prop(:pr_id), 2222)
        assert_equal(storageNew.prop(:message), "hello world")
        
        options = {
            challenge: "#{uuid}_*",
            path: @path,
        }
        StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, options).append!({
            counter: 02,
            pr_id: 8080,
            message: "good bye",
        })

        count = Dir.glob(File.join(@path, "#{uuid}*")).count
        assert_equal(3, count)
                
        StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
            challenge: "#{uuid}*",
            path: Constants::STORE_PATH,
            records: {}
        }).remove!
    end

    def test_removeFile
        File.write(File.join(Constants::STORE_PATH, '94308_Test'), 'test')

        assert_nothing_raised do
            StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
                challenge: "94308*",
                path: Constants::STORE_PATH,
                records: {}
            }).remove!
        end

        assert(FileTest.exist?(File.join(Constants::STORE_PATH, "94308*")) == false, "no file")
    end

end