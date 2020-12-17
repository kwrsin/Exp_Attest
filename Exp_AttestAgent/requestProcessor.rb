require 'singleton'


module RequestProcessor
    class Processor
        include Singleton
        def process(request, metric)
            action = request['action']
            case action
            when 'get_contents'
                "PREMIUM CONTENT #{request['challenge']}, metric #{metric}"                
            else
                "NO DATA"
            end
        end
    end
end