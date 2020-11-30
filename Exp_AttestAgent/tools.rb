require 'securerandom'


def uuid
    SecureRandom.uuid.to_str.split("-").join
end