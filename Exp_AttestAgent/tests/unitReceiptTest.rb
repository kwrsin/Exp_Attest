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
    #     appId = ENV['ATTEST_APPID'] || ''
    #     filename = "test_Attested"
    #     lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
    #         challenge: filename,
    #         path: Constants::STORE_PATH,
    #     })
    #     receipt = lastReceipt.prop(:receipt)
    #     challenge = lastReceipt.prop(:challenge)
    #     cert = lastReceipt.prop(:intermidiate_cartification)
    #     receiptObject = ReceiptObjectAnalyzer.new(receipt, challenge, cert, appId)
    #     receiptObject.verify!
    # end

    def test_env
        puts ENV['ATTEST_APPID']
        puts ENV['P8_PATH']
        puts ENV['TEAM_ID']
    end
end