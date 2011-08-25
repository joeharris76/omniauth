require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    class Dropbox < OmniAuth::Strategies::OAuth
      def initialize(app, consumer_key = nil, consumer_secret = nil, options = {}, &block)
        client_options = {
           :request_token_path => "https://api.dropbox.com/0/oauth/request_token",
           :access_token_path  => "https://api.dropbox.com/0/oauth/access_token",
           :authorize_path     => "https://www.dropbox.com/0/oauth/authorize"
        }
        super(app, :dropbox, consumer_key, consumer_secret, client_options, options, &block)
      end

      def user_data
        @data ||= MultiJson.decode(@access_token.get('/0/account/info').body)
      end

      def auth_hash
        names = user_data['display_name'].split
        last_name = names.pop
        first_name = names.join(' ')
        OmniAuth::Utils.deep_merge(super, {'uid'       => user_data['uid'],
                                           'user_info' => {'email'      => user_data['email'],
                                                           'name'       => user_data['display_name'],
                                                           'first_name' => first_name,
                                                           'last_name'  => last_name,
                                                           'country'    => user_data['country']},
                                           'extra'     => {'quota_info'    => user_data['quota_info'],
                                                           'referral_link' => user_data['referral_link']}})
      end
    end
  end
end
