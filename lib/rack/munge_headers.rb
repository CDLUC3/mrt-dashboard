module Rack
  class MungeHeaders
    def initialize(app, config)
      @app, @config = app, config
    end

    def call(env) 
      res = @app.call(env) 
      path = env["PATH_INFO"] 
      @config[:patterns].each do |pattern, headers| 
        if pattern.match(path)
          headers.each do |header, value|
            res[1][header] = case value
                             when Proc then value.call()
                             else value
                             end
          end
        end 
      end 
      return res
    end
  end
end
