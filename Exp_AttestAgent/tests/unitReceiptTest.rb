require 'test/unit'
require './storageManager'
require './receiptObjectAnalyzer'
require './metricObjectAnalyzer'
require 'jwt'

class TC_ReceiptObjectAnalyzer < Test::Unit::TestCase
    def setup
        # count = Dir.glob(File.join(Constants::STORE_PATH, mask)).coucnt + 1
        # ReceiptObjectAnalyzer.save!("test0001", {response: "3333"}, count)
    end

    def teardown
    end

    # def test_exchangeReceipt
    #     ReceiptObjectAnalyzer.exchangeReceipt(lastReceipt, "test0001", :development)
    # end

    # def test_verify!
    #     appId = ENV['ATTEST_APPID']
    #     keyName = "test_Attested"
    #     lastReceipt = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
    #         challenge: keyName,
    #         path: Constants::STORE_PATH,
    #     })
    #     receipt = lastReceipt.prop(:receipt)
    #     challenge = lastReceipt.prop(:challenge)
    #     cert = lastReceipt.prop(:intermidiate_certification)
    #     receiptObject = ReceiptObjectAnalyzer.new(receipt, challenge, cert, appId)
    #     receiptObject.verify!
    # end

    # def test_jwt
    #     # jwt = "eyJraWQiOiJaQVgzQThHRDJSIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiIyNk5YRTQ3SE4yIiwiaWF0IjoxNjA3NzY0NTE3fQ.QD_Hk2_0RM_dKmVayC8u5Py6uH8OJIgstd-r0DWu5LvL4R3rU1-l_H39wBfsKd97ICa-63WwALsohjUukee3hA"
    #     # jwt = ReceiptObjectAnalyzer.getJWT
    #     begin
    #         key = OpenSSL::PKey::EC.new(
    #         File.read(
    #         File.join(Constants::STORE_PATH, ENV['P8_PATH'])))
    #         decoded_token = JWT.decode jwt, key, true, {algorithm: 'ES256'}
    #         p decoded_token
    #     rescue
    #         puts 'error========================>'
    #     end   
    # end

    # def test_exchangeReceipt
    #     keyName = "test_Attested"
    #     lastReceipt = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
    #         challenge: keyName,
    #         path: Constants::STORE_PATH,
    #     })
    #     receipt = lastReceipt.prop(:receipt)
    #     challenge = lastReceipt.prop(:challenge)
        
    #     rc = ReceiptObjectAnalyzer.exchangeReceipt(receipt, challenge, :development)
    #     # File.write(File.join(Constants::STORE_PATH, 'receipt.bin2'), rc) if rc
    # end


    # def test_analyze_returned_receipt
    #     receiptBase64 = File.read(
    #         File.join(Constants::STORE_PATH, "returnNewReceipt.txt")
    #     )
        
    #     receipt = Base64.decode64 receiptBase64

    #     appId = ENV['ATTEST_APPID']
    #     keyName = "test_Attested"
    #     lastReceipt = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
    #         challenge: keyName,
    #         path: Constants::STORE_PATH,
    #     })
    #     challenge = lastReceipt.prop(:challenge)
    #     cert = lastReceipt.prop(:intermidiate_certification)
    #     receiptObject = ReceiptObjectAnalyzer.new(receipt, challenge, cert, appId)
    #     assert_raise do
    #         receiptObject.verify!
    #     end
    # end

    # def test_isExpired?
        # keyName = "test_Receipt_*"
        # lastReceipt = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
        #     challenge: keyName,
        #     path: Constants::STORE_PATH,
        # }).prop
        # receiptObject = ReceiptObjectAnalyzer.new(lastReceipt)
        # assert_equal receiptObject.isExpired?, false
        # p receiptObject.getMetric
    #     p MetricObjectAnalyzer.metricFromLastReceipt "e0f10e0a1fcd4206b6685789a570c92c"
    # end

    def test_canUpdateAttestation?
        answer =  ReceiptObjectAnalyzer.canUpdateAttestation? "dummy"
        assert_equal Constants::RESPONSE_SUCCESS, answer

        answer =  ReceiptObjectAnalyzer.canUpdateAttestation? "canupdattest"
        assert_equal Constants::RESPONSE_SUCCESS, answer
    end
end