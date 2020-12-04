require 'singleton'


module RequestProcessor
    class Processor
        include Singleton
        def process(request)
            action = request['action']
            case action
            when 'get_contents'
                "PREMIUM CONTENT #{request['challenge']}"                
            else
                "NO DATA"
            end
        end
    end
end