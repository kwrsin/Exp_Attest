require 'singleton'

require './tools'

class ChallengeFactory
    @@path = './dump'
    include Singleton

    def initialize
        @challenges = {}
        load
    end

    def challenge(key)
        if key != nil
            return @challenges[key]
        else
            newchallenge = {}
            newchallenge[:uuid] = uuid
            newchallenge[:create_at] = Time.now.to_i
            @challenges[newchallenge[:uuid]] = newchallenge
            save
            return newchallenge
        end
    end

    def set(id, params)
        challenge = @challenges[id]
        if challenge != nil
            params.each do |key, value|
                challenge[key.to_sym] = value
            end
            @challenges[id] = challenge
            save
        end
    end

    def save
        dump = Marshal.dump(@challenges)
        File.write(@@path, dump)
    end

    def load
        if FileTest.exist?(@@path)
            @challenges = Marshal.load(File.read(@@path))
        end
    end

    def getChallenges
        @challenges
    end
end