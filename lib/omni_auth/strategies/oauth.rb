module OmniAuth
  module Strategies
    class OAuth
      include OmniAuth::Strategy
      
      def initialize(app, name, consumer_key, consumer_secret, options = {})
        require 'oauth'
        super
        @consumer = ::OAuth::Consumer.new(consumer_key, consumer_secret, options)
      end
      attr_reader :name, :consumer
    
      def request_phase
        request_token = consumer.get_request_token(:oauth_callback => full_host + "#{OmniAuth.config.path_prefix}/#{name}/callback")
        (session[:oauth]||={})[name.to_sym] = {:callback_confirmed => request_token.callback_confirmed?, :request_token => request_token.token, :request_secret => request_token.secret}
        r = Rack::Response.new
        r.redirect request_token.authorize_url
        r.finish
      end
    
      def callback_phase
        request_token = ::OAuth::RequestToken.new(consumer, session[:oauth][name.to_sym].delete(:request_token), session[:oauth][name.to_sym].delete(:request_secret))
        @access_token = request_token.get_access_token(:oauth_verifier => request.params['oauth_verifier'])
        
        request['auth'] = self.auth_hash
        
        @app.call(self.env)
      rescue ::OAuth::Unauthorized
        fail!(:invalid_credentials)
      end
      
      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'credentials' => {
            'token' => @access_token.token, 
            'secret' => @access_token.secret
          }, 'extra' => {
            'access_token' => @access_token
          }
        })
      end
      
      def unique_id
        nil
      end
    end
  end
end