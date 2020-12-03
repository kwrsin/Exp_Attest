require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/custom_logger'
require 'logger'
require 'fileutils'
require './constants'
require './challengeFactory'
require './attestationObjectAnalyzer'
require './assertionObjectAnalyzer'

set :bind, '0.0.0.0'

configure do
    set :cf, (ChallengeFactory.instance().setting do |me| me.path Constants::STORE_PATH end)
    set :store_path, Constants::STORE_PATH
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
        appId = ENV['ATTEST_APPID'] || ''
        
        analyzer = AttestationObjectAnalyzer.new(params[:keyId], params[:attestation], uuid, appId)
        result = Constants::RESPONSE_SUCCESS if analyzer.saveAttestedObject!
    rescue => error
        logger.error error.message
    end

    json :result => result
end

post '/assertion' do
    result = Constants::RESPONSE_FAULT
    begin
        appId = ENV['ATTEST_APPID'] || ''

        analyzer = AssertionObjectAnalyzer.new(params[:clientData], params[:assertion], appId)
        result = Constants::RESPONSE_SUCCESS if analyzer.updateCounter!
    rescue => error
        logger.error error.message
    end

    json :result => "HELLOWORLD => #{result}"
end

delete '/checked/:uuid' do
    result = Constants::RESPONSE_FAULT
    begin
        path = File.join(Constants::STORE_PATH, "#{params[:uuid]}*")
        FileUtils.rm(Dir.glob(path))

        result = Constants::RESPONSE_SUCCESS
    rescue => error
        logger.error error.message
    end

    json :result => "#{result}"
end
