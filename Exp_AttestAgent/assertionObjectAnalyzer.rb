require 'rubygems'
require 'bundler/setup'

require './constants'
require './attestationObjectAnalyzer'
require './strageManager'
require 'json'
require 'base64'
require 'cbor'
require 'openssl'

class AssertionObjectAnalyzer < AttestationObjectAnalyzer

    def initialize(clientData, assertionObject, appId)
        @clientData = Base64.decode64(clientData)
        @assertionObject = Base64.decode64(assertionObject)
        @appId = appId
        @cb = CBOR.decode(@assertionObject)
        @parsedClientData = JSON.parse(@clientData)
        @signature = @cb["signature"]
        auth_data = @cb["authenticatorData"]
        @rp_id_hash,
        @flags,
        @counter = [
            auth_data.byteslice(0...32),
            auth_data.byteslice(32),
            auth_data.byteslice(33...37),
            # auth_data.byteslice(33...-1)
        ]
        @filename = "#{@parsedClientData["challenge"]}_Attested"
        @records = StrageManager::Strage.instance().getStrage(:file, {
            challenge: @filename,
            path: Constants::STORE_PATH
        }).load!
        @keyId = @records[:keyId]
        @intermidiate_cartification =
            OpenSSL::X509::Certificate.new(@records[:intermidiate_cartification])
    end

    public
    def verify!
        # STEP1
        h = appendHash(@cb['authenticatorData'], @clientData)
        
        # STEP2
        nonce = getNonceFromAuthData(h)

        # STEP3
        raise "invalid signature" if !validSignature?(nonce)

        # STEP4
        raise 'key is invalid!!' if !isValidKeyId?

        # STEP5
        counter = newCounter
        raise 'counter is invalid!!' if counter < 0

        # STEP6
        raise 'challenge is invalid!!' if !validChallenge?
        
        return counter
    end

    def validSignature?(nonce)
        return true if @intermidiate_cartification.public_key.verify(
            OpenSSL::Digest::SHA256.new, @signature, nonce)
        return false
    end

    def newCounter
        count = getCounter
        return count if (@records[:counter] + 1) <= count
        # strict checking
        # return count if (@records[:counter] + 1) == count

        return -1
    end

    def validChallenge?
        @parsedClientData["challenge"] == @records[:challenge]
    end

    def updateCounter!
        counter = verify!
        if counter > 0
            @records[:counter] = counter
            StrageManager::Strage.instance().getStrage(:file, {
                challenge: @filename,
                path: Constants::STORE_PATH,
            }).update!({
                counter: counter,
            })
            return true
        end
        raise 'updating fault!!'
    end
end