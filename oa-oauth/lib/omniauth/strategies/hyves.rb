require 'omniauth/oauth'
require 'multi_json'


module OmniAuth
  module Strategies
    class Hyves < OmniAuth::Strategies::OAuth
      def initialize(app, app_id, app_secret, options = {})
        super(app, :hyves, app_id, app_secret, 
              :request_token_path => request_token_path,
              :authorize_path => "http://www.hyves.nl/api/authorize",
              :access_token_path => access_token_path,
              :http_method => :get,
              :scheme => :header)
      end
      
      def auth_hash
        hash = user_hash(@access_token)   
                     
        {
          "provider" => "hyves",
          "uid" => hash["userid"],
          "user_info" => {
            "name" => hash["firstname"] + " " + hash["lastname"],
            "first_name" => hash["firstname"],
            "last_name" => hash["lastname"]
          },
          "credentials" => {
            "token" => @access_token.token,
            "secret" => @access_token.secret
          }
        }
      end
      
      def user_hash(access_token)
        res = MultiJson.decode( access_token.get("http://data.hyves-api.nl/?userid=#{access_token.params[:userid]}&ha_method=users.get&#{default_options}").body )
        res["user"].first
      end
      
      def request_token_path
        "https://data.hyves-api.nl/?#{request_token_options}&#{default_options}"
      end
      
      def access_token_path
        "https://data.hyves-api.nl/?#{access_token_options}&#{default_options}"
      end
      
      def default_options
        serialize( { :ha_version => "2.0", :ha_format => "json", :ha_fancylayout => false } )            
      end
      
      def request_token_options
        serialize( { :methods => "users.get,friends.get,wwws.create", :ha_method => "auth.requesttoken", :strict_oauth_spec_response => true } )          
      end
      
      def access_token_options
        serialize( { :ha_method => "auth.accesstoken", :strict_oauth_spec_response => true } )
      end
      
      def serialize(options)
        options.collect {|k,v| "#{k}=#{v.to_s}"}.join('&')
      end      
    end
  end
end