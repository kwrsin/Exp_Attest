require 'rubygems'
require 'bundler/setup'

require './constants'
require './storageManager'
require 'base64'
require 'cbor'
require 'openssl'
# require 'net/http'

# REF: https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server
class AttestationObjectAnalyzer
    APPLE_OID = '1.2.840.113635.100.8.2'

    def initialize(keyId, attestationObject, challenge, appId)
        @keyId = Base64.decode64(keyId)
        @attestationObject = Base64.decode64(attestationObject)
        @appId = appId
        @challenge = challenge
        @cb = CBOR.decode(@attestationObject)
        ca_pem = getCAPem

        @ca_certification = 
            OpenSSL::X509::Certificate.new(ca_pem)
        @intermidiate_certification =
            OpenSSL::X509::Certificate.new(@cb['attStmt']['x5c'][0])
        @leaf_certification =
            OpenSSL::X509::Certificate.new(@cb['attStmt']['x5c'][1])

        # REF: https://www.w3.org/TR/webauthn/#fig-attStructs
        auth_data = @cb['authData']
        @rp_id_hash,
        @flags,
        @counter,
        # REF: https://www.w3.org/TR/webauthn/#sec-attested-credential-data
        @aaguid,
        len = [
            auth_data.byteslice(0...32),
            auth_data.byteslice(32),
            auth_data.byteslice(33...37),
            auth_data.byteslice(37...53),
            auth_data.byteslice(53...55)
        ]
        length = (
            ((len.getbyte(0) << 8) & 0xFF) +
            (len.getbyte(1) & 0xFF)
        )            
        @credential_id = auth_data.byteslice(55...(55 + length))

    end

    public
    def verify!
        # STEP1
        raise 'chains are invalid!!' if !isValidChains?
        
        # STEP2
        h = appendHash(@cb['authData'], @challenge)

        # STEP3
        nonce = getNonceFromAuthData(h)

        # STEP4
        raise 'nonce is NOT same!!' unless isSameNonce?(nonce)

        # STEP5
        raise 'key is invalid!!' unless isValidKeyId?

        # STEP6
        raise 'RpId is invalid!!' unless isValidRpId?

        # STEP7
        raise 'Counter is not zero!!' unless isZeroCounter?

        # STEP8
        mode = :production
        mode = :development if isDevelopping?

        # STEP9
        raise 'CredentialId is invalid!!' unless isValidCredentialId?

        return mode
    end

    def saveAttestedObject!
        mode = verify!
        records =  {
            challenge: @challenge,
            keyId: @keyId,
            intermidiate_certification: @cb['attStmt']['x5c'][0],
            leaf_certification: @cb['attStmt']['x5c'][1],
            receipt: @cb['attStmt']['receipt'],
            counter: 0,
            mode: mode,
            challenge_create_at: @cb['create_at'],
        }
        result = StorageManager::Storage.instance().getStorage(Constants::STORAGE_TYPE, {
            challenge: "#{@challenge}_Attested_*",
            path: Constants::STORE_PATH,
            records: records
        }).append!
        return result
        raise 'persistent fault!!'
    end

    private
    def isValidChains?
        # REF: https://my.diffend.io/gems/web_authn/0.4.1/0.5.0#d2h-883949
        store = OpenSSL::X509::Store.new
        store.add_cert @ca_certification
        return store.verify(@intermidiate_certification, [@leaf_certification])
        
        # another workaround??
        # if @intermidiate_certification.verify(@leaf_certification.public_key)
        #     if @leaf_certification.verify(@ca_certification.public_key)
        #         return true
        #     end
        # end
        # return false
    end
    
    def toDigest(value)
        OpenSSL::Digest::SHA256.new(value).digest
    end

    def appendHash(authData, obj)
        digest = toDigest obj
        authData << digest
        authData
    end

    def getNonceFromAuthData(authDataWithObj)
        digest = toDigest authDataWithObj
        digest
    end

    def isSameNonce?(nonce)
        # REF: see isValidChains?'s REF.
        return false if nonce.to_s.empty?
        extension = @intermidiate_certification
            .extensions.detect { |ext|
                ext.oid == APPLE_OID }
        expected_nonce = OpenSSL::ASN1.decode(
            OpenSSL::ASN1.decode(extension.to_der).value.last.value
            ).value.last.value.last.value
        return expected_nonce == nonce
    end

    def isValidKeyId?
        # REF: http://oid-info.com/get/2.5.29.14
        # REF: https://github.com/ruby/openssl/issues/163#issuecomment-339108949
        return false if @keyId.to_s.empty?
        
        public_key = @intermidiate_certification.public_key.to_der
        asn1 = OpenSSL::ASN1.decode(public_key) 
        pub_key = nil 
        asn1.value.each {|v|
            if v.tag == 3 
                pub_key = v.value
            end
        }
        pub_key = toDigest pub_key
        return pub_key == @keyId
    end

    def isValidRpId?
        hashedAppId = toDigest @appId
        hashedRpId = @rp_id_hash
        return hashedAppId == hashedRpId
    end

    def getCounter
        counter = @counter.unpack('N1').first
        counter
    end

    def isZeroCounter?
        return getCounter === 0
    end

    def isDevelopping?
        # TODO: appattest followed by seven 0x00 bytes if operating in the production environment.
        return @aaguid.include? "appattestdevelop"
    end

    def isValidCredentialId?
        return @credential_id == @keyId
    end

    protected
    def getCAPem
        # ca_pem = Net::HTTP.get(URI('https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem'))
        ca_pem = <<~PEM
-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijV
oyFraWVIyd/dganmrduC1bmTBGwD
-----END CERTIFICATE-----
PEM
        ca_pem
    end

    # def self.convertPublicKey(certification)
    #     return nil if certification.to_s.empty?
        
    #     public_key = certification.public_key.to_der
    #     asn1 = OpenSSL::ASN1.decode(public_key) 
    #     pub_key = nil 
    #     asn1.value.each {|v|
    #         if v.tag == 3 
    #             pub_key = v.value
    #         end
    #     }
    #     pub_key
    # end
end