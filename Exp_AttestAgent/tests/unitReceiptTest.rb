require 'test/unit'
require './strageManager'
require './receiptObjectAnalyzer'
require 'jwt'

class TC_ReceiptObjectAnalyzer < Test::Unit::TestCase
    def setup
        # count = Dir.glob(File.join(Constants::STORE_PATH, mask)).coucnt + 1
        # ReceiptObjectAnalyzer.save!("test0001", {response: "3333"}, count)
    end

    def teardown
    end

    # def test_requestReceipt
    #     ReceiptObjectAnalyzer.requestReceipt(lastReceipt, "test0001", :development)
    # end

    # def test_verify!
    #     appId = ENV['ATTEST_APPID']
    #     keyName = "test_Attested"
    #     lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
    #         challenge: keyName,
    #         path: Constants::STORE_PATH,
    #     })
    #     receipt = lastReceipt.prop(:receipt)
    #     challenge = lastReceipt.prop(:challenge)
    #     cert = lastReceipt.prop(:intermidiate_cartification)
    #     receiptObject = ReceiptObjectAnalyzer.new(receipt, challenge, cert, appId)
    #     receiptObject.verify!
    # end

    # def test_jwt
    #     # jwt = "eyJraWQiOiJaQVgzQThHRDJSIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiIyNk5YRTQ3SE4yIiwiaWF0IjoxNjA3NzY0NTE3fQ.QD_Hk2_0RM_dKmVayC8u5Py6uH8OJIgstd-r0DWu5LvL4R3rU1-l_H39wBfsKd97ICa-63WwALsohjUukee3hA"
    #     jwt = ReceiptObjectAnalyzer.getJWT
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

    # def test_requestReceipt
    #     keyName = "test_Attested"
    #     lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
    #         challenge: keyName,
    #         path: Constants::STORE_PATH,
    #     })
    #     receipt = lastReceipt.prop(:receipt)
    #     challenge = lastReceipt.prop(:challenge)
        
    #     ReceiptObjectAnalyzer.requestReceipt(receipt, challenge, :development)
    # end


    def test_analyze_returned_receipt
        receiptBase64 = File.read(
            File.join(Constants::STORE_PATH, "returnNewReceipt.txt")
        )
        
        receipt = Base64.decode64 receiptBase64

        appId = ENV['ATTEST_APPID']
        keyName = "test_Attested"
        lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: keyName,
            path: Constants::STORE_PATH,
        })
        challenge = lastReceipt.prop(:challenge)
        cert = lastReceipt.prop(:intermidiate_cartification)
        receiptObject = ReceiptObjectAnalyzer.new(receipt, challenge, cert, appId)
        assert_raise do
            receiptObject.verify!
        end

    end
end