require 'securerandom'


def generateUuid
    SecureRandom.uuid.to_str.split("-").join
end