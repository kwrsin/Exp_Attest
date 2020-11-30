require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/json'
require './challengeFactory'
require './attestationObjectAnalyzer'

set :bind, '0.0.0.0'

configure do
    set :cf, ChallengeFactory.instance
end

get '/' do
    "let\'s attest. #{ENV['ATTEST_APPID']}"
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
    AttestationObjectAnalyzer.new(params[:keyId], params[:attestation], uuid, appId)

    json :req => 'ok'
end

