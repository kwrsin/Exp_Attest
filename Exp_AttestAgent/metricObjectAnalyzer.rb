require 'openssl'

require './receiptObjectAnalyzer'

class MetricObjectAnalyzer < ReceiptObjectAnalyzer
    def initialize(receipt)
        @receipt = receipt
        @pkcs7 = OpenSSL::PKCS7.new(@receipt)
        octetstring = OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[2].value[1].value[0].value
        @fields = OpenSSL::ASN1.decode(octetstring).value
    end

    def isExpired?
        notBeforeTime = Time.parse(field(FIELD_NOT_BEFORE))
        expirationTime = Time.parse(field(FIELD_EXPIRERATION_TIME))
        currentTime = Time.now
        return true unless currentTime < notBeforeTime
        currentTime > expirationTime
    end

    def self.metricFromLastReceipt(challenge)
        keyName = "#{challenge}_Receipt_*"
        lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: keyName,
            path: Constants::STORE_PATH,
        }).prop
        receiptObject = MetricObjectAnalyzer.new(lastReceipt)
        return Constants::NO_METRIC if receiptObject.isExpired?
        return receiptObject.getMetric
    end
end