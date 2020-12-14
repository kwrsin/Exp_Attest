require 'base64'
require 'openssl'
require 'net/http'
require 'cbor'
require 'time'
require 'json'

require './constants'
require './strageManager'
require './attestationObjectAnalyzer'

class ReceiptObjectAnalyzer < AttestationObjectAnalyzer
    def initialize(receipt, challenge, cert, appId)
        @receipt = receipt
        @challenge = challenge
        @appId = appId
        @pkcs7 = OpenSSL::PKCS7.new(@receipt)
        octetstring = OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[2].value[1].value[0].value
        @fields = OpenSSL::ASN1.decode(octetstring).value

        # REF: https://developer.apple.com/documentation/devicecheck/assessing_fraud_risk
        ca_pem = File.read(Constants::ATTEST_APPLE_ROOT_CA_PATH)
        @ca_cartification = 
            OpenSSL::X509::Certificate.new(ca_pem)
        @intermidiate_cartification = OpenSSL::X509::Certificate.new(OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[3].value[1])
        @leaf_cartification = OpenSSL::X509::Certificate.new(OpenSSL::ASN1.decode(@pkcs7.to_der).value.last.value.first.value[3].value[2])
        @attestedPK = OpenSSL::X509::Certificate.new(cert).public_key

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

    NO_METRIC = -1

    def field(field)
        field = @fields.find do |v|
            v.value[0].value == field
        end
        field.value.last.value if field 
    end

    def verify!
        # REF: https://developer.apple.com/documentation/devicecheck/assessing_fraud_risk

        #STEP1
        raise 'the Signature is invalid' unless isValidSignature? 

        #STEP2
        raise 'chains are invalid!!' unless isValidChains?
        
        #STEP3
        # REF: SEE initialize

        #STEP4
        raise 'an appId is not match to a receipt\'s one.' unless isSameAppId?
        
        #STEP5
        raise '5 minutes over' if fiveMinutesOver?
        
        #STEP6
        raise 'the public key is invalid' unless isValidPublicKey?
        
        # Interpret the Metric
        return getMetric
    end

    def getMetric
        return field(FIELD_RISK_METRIC).to_i if(field(FIELD_RECEIPT_TYPE).to_sym == :RECEIPT)
        return NO_METRIC
    end

    def isValidPublicKey?
        cert = OpenSSL::X509::Certificate.new field(FIELD_ATTEST_PUBLIC_KEY)
        cert.public_key.to_pem == @attestedPK.to_pem
    end

    def isSameAppId?
        field(FIELD_APPID) == @appId
    end

    def fiveMinutesOver?
        creationTime = Time.parse(field(FIELD_CREATION_TIME))
        Time.now - creationTime > 300 
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

    def self.asn1_to_raw(signature, public_key)
        # REF: https://github.com/jwt/ruby-jwt/blob/fb29072d96110d15423df1113e43d8cfb5cf279c/lib/jwt/security_utils.rb#L29
        byte_size = (public_key.group.degree + 7) / 8
        OpenSSL::ASN1.decode(signature).value.map { |value| value.value.to_s(2).rjust(byte_size, "\x00") }.join
    end

    def self.encode64(str)
        Base64.encode64(str).tr('+/', '-_').gsub(/[\n=]/, '')
    end

    def self.getJWT
        # REF: https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns#2947602
        keyId = ENV['JWT_KEY_ID']
        teamId = ENV['TEAM_ID']
        path = ENV['P8_PATH']
        params = []
        params << ReceiptObjectAnalyzer.encode64({
            :kid => "#{keyId}",
            :alg => "ES256",
        }.to_json)
        params << ReceiptObjectAnalyzer.encode64({
            :iss => "#{teamId}",
            :iat => Time.now.to_i
        }.to_json)
        headerAndPlayload = params.join('.')
        # REF: https://stackoverrun.com/ja/q/1139890
        key = OpenSSL::PKey::EC.new(
            File.read(
                File.join(Constants::STORE_PATH, path)))

        # REF: https://github.com/jwt/ruby-jwt/blob/fb29072d96110d15423df1113e43d8cfb5cf279c/lib/jwt/algos/ecdsa.rb#L13
        digest = OpenSSL::Digest.new('sha256')
        signature = key.dsa_sign_asn1(digest.digest(headerAndPlayload))
        signedSignature = ReceiptObjectAnalyzer.asn1_to_raw signature, key
        params << ReceiptObjectAnalyzer.encode64(signedSignature)
        "#{params.join('.')}"
    end

    def self.requestReceipt(lastReceipt, challenge, mode)
        jwt = ReceiptObjectAnalyzer.getJWT()
        uri = mode == :production ? 
            URI(Constants::APPLE_URL_PRDUCTION) :
            URI(Constants::APPLE_URL_DEVLOPMENT)

        unless lastReceipt
            mask = "#{challenge}_Receipt_*"
            files = Dir.glob(File.join(Constants::STORE_PATH, mask))
            keyName = files.sort.last || ""
            raise "could not find a last receipt." if keyName.empty?
            
            lastReceipt = StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
                challenge: keyName,
                path: Constants::STORE_PATH,
            })
            raise "could not get a last receipt." unless lastReceipt
        end

        # !!Must Use Strict encoding
        base64Receipt = Base64.strict_encode64(lastReceipt)
        receipt = nil
        req = Net::HTTP::Post.new(uri.path)
        req.add_field 'Authorization', "Bearer #{jwt}"
        req.body = base64Receipt

        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
            http.request(req)
        end

        if res.code == 200
            res.read_body do |new_receipt|
                receipt = Base64.decode64(new_receipt)
                ReceiptObjectAnalyzer.save!(challenge, receipt, files.count + 1)
            end
        else
            raise "response status error. #{ReceiptStatus::RESPONSE_STATUS[res.code.to_s] || ''}"
        end

        return receipt
    end

    def self.save!(challenge, receipt, count = 0)
        StrageManager::Strage.instance().getStrage(Constants::STRAGE_TYPE, {
            challenge: "#{challenge}_Receipt_#{count.to_s.rjust(Constants::COLUMN_WIDTH, '0')}",
            path: Constants::STORE_PATH,
            records: receipt
        }).save!
    end
end