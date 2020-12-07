require 'singleton'
require './constants'
require './tools'

module StrageManager
    class Strage
        include Singleton

        def getStrage(strageType = :file, options = nil)
            case strageType
            when :db
                return StrageHelpers::DBStrage.new(options)
            else
                return StrageHelpers::FileStrage.new(options)
            end
        end
    end
    
    private
    module StrageHelpers
        class BaseStrage
            @records = nil
            @strageName = :Base
            def initialize(options)
                if options
                    @options = options
                    @path = File.join(@options[:path], @options[:challenge])
                    if options[:records]
                        @records = options[:records]
                    else
                        load!
                    end
                else
                    raise "Must options"
                end
            end

            protected
            def load!
                raise "load! is Not Implemented!!"
            end

            public
            def save!(diff)
                raise "save! is Not Implemented!!"
            end
            
            def update!
                raise "update! is Not Implemented!!"
            end
            
            def remove!
                raise "remove! is Not Implemented!!"
            end

            def merge(diff)
                @records.merge(diff) if diff
            end

            def prop(key)
                @records[key]
            end

            def getMode!
                raise "getMode! is Not Implemented!!"
            end

        end

        class FileStrage < BaseStrage
            @strageName = :File

            def load!
                @records = Marshal.load(File.read(@path)) if FileTest.exists? @path
                @records ||= {}
            end

            def save!(diff = nil)
                raise "could not save @path." if FileTest.exists? @path
                update!(diff)     
            end
            
            def update!(diff = nil)
                @records = merge(diff) if diff
                records = Marshal.dump(@records)
                File.write(@path, records)
                @records       
            end

            def remove!
                deleteFiles(@path)
            end

            def getMode!
                raise "getMode! is Not Implemented!!"
            end

        end

        class DBStrage < BaseStrage
            @strageName = :DB
        end
    end
end