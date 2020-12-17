require 'singleton'
require './constants'
require './tools'

module StrageManager
    class Strage
        include Singleton

        def getStrage(strageType = Constants::STRAGE_TYPE, options = nil)
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

            def lastRecord!
                raise "lastRecord! is Not Implemented!!"
            end

            public
            def save!(diff)
                raise "save! is Not Implemented!!"
            end
            
            def append!(diff)
                raise "append! is Not Implemented!!"
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

            def prop(key = nil)
                return @records[key] if key
                @records
            end

        end

        class FileStrage < BaseStrage
            @strageName = :FILE

            def load!
                filename = lastRecord!
                filepath = File.join(@options[:path], filename)
                @records = Marshal.load(File.read(filepath)) if FileTest.exist? filepath
                @records ||= {}
            end

            def save!(diff = nil)
                raise "could not save #{@path}." if FileTest.exist? @path
                update!(diff)     
            end
            
            def append!(diff = nil)
                count = Dir.glob(@path).count
                count += 1
                filename = "#{@options[:challenge]}"
                                .sub('_*', "_#{count.to_s.rjust(Constants::COLUMN_WIDTH, '0')}")
                @path = File.join(@options[:path], filename)
                save!(diff)
            end
            
            def update!(diff = nil)
                @records = merge(diff) if diff
                records = Marshal.dump(@records)
                File.write(@path, records)
                @records       
            end

            def remove!
                deleteFiles(@path) if Dir.glob(@path).count > 0
            end

            def lastRecord!
                files = Dir.glob(@path)
                filename = files.sort.last || ""
                raise "could not find a last file." if filename.empty?
                filename
            end

        end

        class DBStrage < BaseStrage
            @strageName = :DB
        end
    end
end