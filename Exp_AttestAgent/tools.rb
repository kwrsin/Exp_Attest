require 'constants'
require 'securerandom'


def generateUuid
    SecureRandom.uuid.to_str.split("-").join
end

def deleteAttestedFiles(challenge)
    path = File.join(Constants::STORE_PATH, "#{challenge}*")
    FileUtils.rm(Dir.glob(path))
end