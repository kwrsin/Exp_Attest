require 'base64'
require 'openssl'
require 'net/http'
require 'cbor'

require './constants'
require './strageManager'
require './attestationObjectAnalyzer'



class ReceiptObjectAnalyzer < AttestationObjectAnalyzer
    def initialize(receipt, challenge)
        @receipt = receipt
        @challenge = challenge

        @pkcs7 = OpenSSL::PKCS7.new(@receipt)
        octetstring = OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[2].value[1].value[0].value
        @fields = OpenSSL::ASN1.decode(octetstring).value

        # REF: https://developer.apple.com/documentation/devicecheck/assessing_fraud_risk
        ca_pem = File.read("./AppleRootCA-G3.cer")
        @ca_cartification = 
            OpenSSL::X509::Certificate.new(ca_pem)
        @intermidiate_cartification = OpenSSL::X509::Certificate.new(OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[3].value[1])
        @leaf_cartification = OpenSSL::X509::Certificate.new(OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[3].value[2])

    end

    FIELD_APPID = 2
    FIELD_ATTEST_PUBLIC_KEY = 3
    FIELD_CLIENT_HASH = 4
    FIELD_TOKEN = 5
    FIELD_RECEIPT_TYPE = 6
    FIELD_CREATION_TIME = 12
    FIELD_RISK_METRIC = 17
    FIELD_NOT_BEFORE = 19
    FIELD_EXPIRERATION_TIME = 21

    def field(field)
        field = @fields.find do |v|
            v.value[0].value == field
        end
        field.value.last.value if field 
    end

    def verify!
        # octetstring = OpenSSL::ASN1.decode(pkcs7.to_der).value.last.value.first.value[4].value.last.value.last.value
        # fields = OpenSSL::ASN1.decode(octetstring).value
        # p fields

        #STEP1
        raise 'the Signature is invalid' unless isValidSignature? 

        #STEP2
        raise 'chains are invalid!!' unless isValidChains?
        
        #STEP3
        # REF: SEE initialize

        #STEP4
        # raise 'an appId is not match to a receipt\'s one.' unless isSameAppId?

        #STEP5
        # raise '5 minutes over' unless fiveMinutesOver?
        
        #STEP6
        # raise 'the public key is invalid' unless isValidPK?

        # TODO: Metric checking
    end

    def isValidPK?
    end

    def isSameAppId?
    end

    def fiveMinutesOver?
    end

    def isValidSignature?
        store = OpenSSL::X509::Store.new
        store.add_cert @ca_cartification
        @pkcs7.verify(nil, store)
    end

    module ReceiptStatus
        RESPONSE_STATUS = {
            "200": {error: nil},
            "304": {error: "Not Modified"},
            "400": {error: "Incorrect Environment or Bad Payload"},
            "401": {error: "Unauthorized"},
            "404": {error: "No Data Found"},
            "429": {error: "Too Many Requests"},
            "500": {error: "Server Error"},
            "503": {error: "Service Unavailable"},
        }
    end
    def self.requestReceipt(challenge, mode)
        jwt = ENV['JWT']
        url = mode == :production ? 
            Constants::APPLE_URL_PRDUCTION :
            Constants::APPLE_URL_DEVLOPMENT

        # mask = "#{challenge}_Receipt_*"
        # files = Dir.glob(File.join(Constants::STORE_PATH, mask))
        # filename = files.sort.last || ""
        # raise "could not find last receipt." if filename.empty?
        
        # lastReceipt = StrageManager::Strage.instance().getStrage(:file, {
        #     challenge: filename,
        #     path: Constants::STORE_PATH,
        # })
        # raise "could not get last receipt." unless lastReceipt

        receipt = nil
        # http.request_post(url, lastReceipt, {
        #     Authorization: jwt
        # }) { |response|
        #     if response.status == 200
        #         response.read_body do |new_receipt|
        #             receipt = new_receipt
        #             ReceiptObjectAnalyzer.save!(challenge, receipt, files.count + 1)
        #         end
        #     else
        #         raise "response status error. #{ReceiptStatus::RESPONSE_STATUS[response.status.to_s] || ''}"
        #     end
        # }    
        return receipt
    end

    def self.save!(challenge, receipt, count = 0)
        StrageManager::Strage.instance().getStrage(:file, {
            challenge: "#{challenge}_Receipt_#{count.to_s.rjust(Constants::COLUMN_WIDTH, '0')}",
            path: Constants::STORE_PATH,
            records: receipt
        }).save!
    end
end