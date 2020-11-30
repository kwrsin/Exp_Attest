
require 'rubygems'
require 'bundler/setup'

require 'base64'

require 'cbor'
# require 'libcbor/all'

require 'openssl'
require 'net/http'

# REF: https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server
class AttestationObjectAnalyzer
    APPLE_OID = '1.2.840.113635.100.8.2'
    SUBJECT_KEYID_OID = 'subjectKeyIdentifier'
    # APPID = '26NXE47HN2.io.github.kwrsin.Exp-Artest'


    def initialize(keyId, attestationObject, challenge, appId)
        @keyId = Base64.decode64(keyId)
        @attestationObject = Base64.decode64(attestationObject)
        # @attestationObject = attestationObject
        # File.write("./aobj", attestationObject)
        # puts @keyId
        @appId = appId
        @cb = CBOR.decode(@attestationObject)
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
        @ca_cartification = 
            OpenSSL::X509::Certificate.new(ca_pem)
        @intermidiate_cartification =
            OpenSSL::X509::Certificate.new(@cb['attStmt']['x5c'][0])
        @leaf_cartification =
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

        # STEP1
        if isValidChains?
            puts 'chains are valid.'
        else
            puts 'chains are invalid!!'
        end
        
        # STEP2
        h = appendChallengeHash(@cb['authData'], challenge)

        # STEP3
        nonce = getNonceFromAuthData(h)

        # STEP4
        if isSameNonce? nonce
            puts 'nonce is same.'
        else
            puts 'nonce is NOT same!!'
        end

        # STEP5
        if isValidKeyId?
            puts 'key is valid.'
        else
            puts 'key is invalid!!'
        end

        # STEP6
        if isValidRrId?
            puts 'RrId is valid.'
        else
            puts 'RrId is invalid!!'
        end

        # STEP7
        if isValidCounter?
            puts 'Counter is zero.'
        else
            puts 'Counter is not zero!!'
        end

        # STEP8
        if isDevelopping?
            puts 'It\'s Delelopment mode. (Aaguid)'
        else
            puts 'It\'s Production mode. (AaguId)'
        end

        # STEP9
        if isValidCredentialId?
            puts 'CredentialId is valid.'
        else
            puts 'CredentialId is invalid!!'
        end

        
    end

    private

    def isValidChains?
        # REF: https://my.diffend.io/gems/web_authn/0.4.1/0.5.0#d2h-883949
        store = OpenSSL::X509::Store.new
        store.add_cert @ca_cartification
        return store.verify(@intermidiate_cartification, [@leaf_cartification])
        
        # another workaround??
        # if @intermidiate_cartification.verify(@leaf_cartification.public_key)
        #     if @leaf_cartification.verify(@ca_cartification.public_key)
        #         return true
        #     end
        # end
        # return false
    end
    
    def toDigest(value)
        OpenSSL::Digest::SHA256.new(value).digest
    end

    def appendChallengeHash(authData, challenge)
        digest = toDigest challenge
        authData << digest
        authData
    end

    def getNonceFromAuthData(authDataWithChallenge)
        digest = toDigest authDataWithChallenge
        digest
    end

    def isSameNonce?(nonce)
        # REF: see isValidChains?'s REF.
        return false if nonce.to_s.empty?
        extension = @intermidiate_cartification
            .extensions.detect { |ext|
                ext.oid == APPLE_OID }
        expected_nonce = OpenSSL::ASN1.decode(
            OpenSSL::ASN1.decode(extension.to_der).value.last.value
            ).value.last.value.last.value
        return expected_nonce == nonce
    end

    def isValidKeyId?
        # REF: http://oid-info.com/get/2.5.29.14
        # TODO: not supported
        return false if @keyId.to_s.empty?
        
        # extension = @leaf_cartification
        #     .extensions.detect { |ext|
        #         ext.oid == SUBJECT_KEYID_OID }
        
        # ext_asn1 = OpenSSL::ASN1.decode(extension.to_der)
        # ext_value = ext_asn1.value.last.value
        # pub_key = ext_value
        pub_key = toDigest @intermidiate_cartification.public_key.to_pem
        # pub_key = OpenSSL::Digest::SHA256.hexdigest(@intermidiate_cartification.public_key.to_der)
        # pub_key = Base64.urlsafe_encode64(pub_key, padding: false)
        puts "#{pub_key} ==> #{@keyId}"
        return pub_key == @keyId
    end

    def isValidRrId?
        hashedAppId = toDigest @appId
        hashedRpId = @rp_id_hash
        return hashedAppId == hashedRpId
    end

    def isValidCounter?
        counter = @counter.unpack('N1').first
        return counter === 0
    end

    def isDevelopping?
        # TODO: appattest followed by seven 0x00 bytes if operating in the production environment.
        return @aaguid.include? "appattestdevelop"
    end

    def isValidCredentialId?
        return @credential_id == @keyId
    end

end