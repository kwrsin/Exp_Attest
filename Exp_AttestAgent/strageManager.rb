require 'singleton'

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
                        load
                    end
                else
                    raise "options Must"
                end
            end

            protected
            def load
                raise "Not Implemented!!"
            end

            public
            def save
                raise "Not Implemented!!"
            end

            def output
                p @records
            end
        end

        class FileStrage < BaseStrage
            @strageName = :File

            def load
                @records = Marshal.load(File.read(@path)) if FileTest.exists? @path
                @records ||= {}
            end

            def save
                records = Marshal.dump(@records)
                File.write(@path, records)        
            end
        end

        class DBStrage < BaseStrage
            @strageName = :DB
        end
    end
end