require 'fileutils'
require 'securerandom'


def generateUuid
    SecureRandom.uuid.to_str.split("-").join
end

def deleteFiles(path)
    FileUtils.rm(Dir.glob(path))
end