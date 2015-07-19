module LetItGo
  module Middleware
    class Olaf
      def initialize(app)
        @app          = app
      end

      def asset_request?(path)
        path.match(/^\/assets\/|favicon.ico$/i)
      end

      def not_asset_request?(path)
        !asset_request?(path)
      end

      def call(env)
        result = nil
        report = LetItGo.record do
          result = @app.call(env)
        end
        puts ""
        report.print if not_asset_request?(env["REQUEST_PATH".freeze])
        result
      end
    end

    # Pick your favorite character!
    Elsa = Olaf
    Anna = Olaf
  end
end
