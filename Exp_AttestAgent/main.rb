require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/custom_logger'
require 'logger'
require './challengeFactory'
require './attestationObjectAnalyzer'

set :bind, '0.0.0.0'

configure do
    set :cf, ChallengeFactory.instance
end

configure :development do
    logger = Logger.new(STDOUT)  
    logger.level = Logger::DEBUG
    set :logger, logger
end

configure :production do
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
    #TODO: priventing multi posts from same user.
    val = settings.cf.challenge(nil)
    json :challenge => val
end

post '/attestation/:uuid' do
    uuid = params[:uuid]
    settings.cf.set(uuid, params)
    appId = ENV['ATTEST_APPID'] || ''
    
    analyzer = AttestationObjectAnalyzer.new(params[:keyId], params[:attestation], uuid, appId)
    begin
        mode = analyzer.verify!
    rescue => error
        logger.error error.message
    end

    json :req => 'ok'
end

