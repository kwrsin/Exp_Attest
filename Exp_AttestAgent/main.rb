require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/custom_logger'
require 'logger'
require './constants'
require './challengeFactory'
require './attestationObjectAnalyzer'
require './assertionObjectAnalyzer'
require './receiptObjectAnalyzer'
require './requestProcessor'

set :bind, '0.0.0.0'

configure do
    set :cf, (ChallengeFactory.instance().setting do |me| me.path Constants::STORE_PATH end)
end

configure :development do
    logger = Logger.new(STDOUT)  
    logger.level = Logger::DEBUG
    set :logger, logger
end

configure :development, :production do
    logger = Logger.new(
        File.open("#{settings.root}/log/#{settings.environment}.log", 'a'))
    set :logger, logger    
end

get '/' do
    logger.debug "ENV=#{ENV['ATTEST_APPID']}"
    "let\'s attest."
end

get '/challenge/:uuid' do
    uuid = params[:uuid]
    val = settings.cf.challenge(uuid)
    #TODO: check if the challenge is expired.
    json :challenge => val
end

get '/challenge' do
    #TODO: setting the challenge's lifetime.
    #TODO: preventing multi posts from same user.
    val = settings.cf.challenge(nil)
    json :challenge => val
end

post '/attestation/:uuid' do
    result = Constants::RESPONSE_FAULT 
    begin
        uuid = params[:uuid]
        settings.cf.set(uuid, params)
        appId = ENV['ATTEST_APPID']
        analyzer = AttestationObjectAnalyzer.new(params[:keyId], params[:attestation], uuid, appId)
        attestedObject = analyzer.saveAttestedObject!
        result = Constants::RESPONSE_SUCCESS if requestMetric!(attestedObject, appId) > 0
    rescue => error
        logger.error error.message
    end

    json :result => result
end

post '/assertion' do
    result = Constants::RESPONSE_FAULT
    begin
        analyzer = AssertionObjectAnalyzer.new(params[:clientData], params[:assertion], ENV['ATTEST_APPID'])
        result = RequestProcessor::Processor.instance().process(analyzer.validatedRequest)
    rescue => error
        logger.error error.message
    end

    json :result => result
end

delete '/checked' do
    result = Constants::RESPONSE_FAULT
    begin
        analyzer = AssertionObjectAnalyzer.new(params[:clientData], params[:assertion], ENV['ATTEST_APPID'])
        result = Constants::RESPONSE_SUCCESS if analyzer.delete!
    rescue => error
        logger.error error.message
    end

    json :result => result
end

def requestMetric!(attestedObject, appId)
    receipt = attestedObject[:receipt]
    challenge = attestedObject[:challenge]
    cert = attestedObject[:intermidiate_certification]
    raise 'could not save a Attested Object' unless attestedObject
    deviceReceiptAnalyzer = ReceiptObjectAnalyzer.new(
        receipt, challenge, cert, appId)

    raise 'invalid device receipt' unless deviceReceiptAnalyzer.verify! == Constants::NO_METRIC
    metricReceipt = ReceiptObjectAnalyzer.exchangeReceipt(
        receipt, challenge, attestedObject[:mode])
    metricReceiptAnalyzer = ReceiptObjectAnalyzer.new(
        metricReceipt, challenge, cert, appId)
        
    metric = metricReceiptAnalyzer.verify!
    raise 'invalid metric receipt' unless metric > 0
    metric
end


