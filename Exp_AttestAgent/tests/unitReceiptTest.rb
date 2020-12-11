require 'test/unit'
require './strageManager'
require './receiptObjectAnalyzer'

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
    #     require 'jwt'
    #    jwt = ReceiptObjectAnalyzer.getJWT2
    #    p jwt
    #    decoded_token = JWT.decode jwt, nil, false
    #    p decoded_token
    #     # payload = { iss: ENV['TEAM_ID'] }
    # #    key = OpenSSL::PKey::EC.new(
    # #     File.read(
    # #         File.join(Constants::STORE_PATH, ENV['P8_PATH'])))
    # #     token = JWT.encode payload, key, 'ES256'
    # #     p "bearer #{token}"
    # end

    def test_requestReceipt
        keyName = "test_Attested"
        lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: keyName,
            path: Constants::STORE_PATH,
        })
        receipt = lastReceipt.prop(:receipt)
        challenge = lastReceipt.prop(:challenge)
        
        ReceiptObjectAnalyzer.requestReceipt(receipt, challenge, :development)
    end
end