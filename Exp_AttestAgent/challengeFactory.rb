require 'singleton'

require './tools'

class ChallengeFactory
    @@path = '../store'
    include Singleton

    def setting(setter = nil)
        setter(self) if setter
        self
    end

    def path(dumpPath = nil)
        if dumpPath
            ChallengeFactory.setDumpPath path
        end
    end

    def self.setDumpPath(path)
        @@path = path
    end

    def challenge(uuid = nil)
        if uuid != nil
            return load! uuid
        else
            newchallenge = {}
            newchallenge[:uuid] = generateUuid()
            newchallenge[:create_at] = Time.now.to_i
            @challenge = newchallenge
            save!
            return @challenge
        end
    end

    def set(uuid, params)
        load! uuid
        return if @challenge == nil || params == nil
        params.each do |key, value|
            @challenge[key.to_sym] = value
        end
        update!
    end

    def save!
        path = File.join(@@path, "#{@challenge[:uuid]}_Dump")
        raise "could not save #{path}." if FileTest.exist?(path)
        update!
    end

    def update!
        path = File.join(@@path, "#{@challenge[:uuid]}_Dump")
        dump = Marshal.dump(@challenge)
        File.write(path, dump)
    end

    def load!(uuid)
        path = File.join(@@path, "#{uuid}_Dump")
        if FileTest.exist?(path)
            @challenge = Marshal.load(File.read(path))
            return @challenge
        end
        raise "could not find #{path}."
    end

    def getChallenge
        @challenge
    end
end