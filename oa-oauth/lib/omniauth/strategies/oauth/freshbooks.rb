require 'omniauth/oauth'
require 'nokogiri'

module OmniAuth
  module Strategies
    class Freshbooks < OmniAuth::Strategies::OAuth
      #Freshbooks requires authenticaion via the user specific subdomain
      #Place into the :site member using Dynamic Providers (:setup => true).
      # get '/auth/:provider/setup' do
      #   request.env['omniauth.strategy'].consumer_options[:site] = "https://#{session[:subdomain]}.freshbooks.com"
      #   halt 404
      # end
      def initialize(app, consumer_key = nil, consumer_secret = nil, options = {}, &block)
        client_options = {
           :site               => "https://subdomain.freshbooks.com", #placeholder site value
           :signature_method   => 'PLAINTEXT',
           :request_token_path => "/oauth/oauth_request.php",
           :access_token_path  => "/oauth/oauth_access.php",
           :authorize_path     => "/oauth/oauth_authorize.php"
        }
        super(app, :freshbooks, consumer_key, consumer_secret, client_options, options, &block)
      end
      
      def auth_hash
        hash = user_hash(@access_token)
        OmniAuth::Utils.deep_merge(super, {
          #Nicknames are not unique across subdomains
          'uid'       => session[:subdomain]+'=>'+hash['staff']['nickname'], 
          'user_info' => {
            'name'        => [hash['staff']['first_name'], hash['last_name']].join(' ').strip,
            'nickname'    => hash['staff']['nickname'],
            'email'       => hash['staff']['email'],
            'first_name'  => hash['staff']['first_name'],
            'last_name'   => hash['staff']['last_name'],
            'phone'       => hash['staff']['work_phone']
          },
          'extra'     => { 
            #Note - Oauth module adds AccessToken to Extra, remove before persisting.
            'staff' => hash['staff']
          }
        })
      end
      
      def user_hash(access_token)
        req = '<?xml version="1.0" encoding="utf-8"?><request method="staff.current"></request>'
        #Freshbooks API is all POST
        rsp = @access_token.post('/api/2.1/xml-in',req).body 
        staff = Nokogiri::XML::Document.parse(rsp).remove_namespaces!
        staff = staff.xpath('response/staff')
        hash = {
          'staff' => {
            'subdomain'    => session[:subdomain],
            'staff_id'     => staff.xpath('staff_id'      ).text,
            'nickname'     => staff.xpath('username'      ).text,
            'first_name'   => staff.xpath('first_name'    ).text,
            'last_name'    => staff.xpath('last_name'     ).text,
            'email'        => staff.xpath('email'         ).text,
            'signup_date'  => staff.xpath('signup_date'   ).text,
            'work_phone'   => staff.xpath('business_phone').text,
            'mobile_phone' => staff.xpath('mobile_phone'  ).text,
            'rate'         => staff.xpath('rate'          ).text,
            'street1'      => staff.xpath('street1'       ).text,
            'street2'      => staff.xpath('street2'       ).text,
            'city'         => staff.xpath('city'          ).text,
            'state'        => staff.xpath('state'         ).text,
            'country'      => staff.xpath('country'       ).text,
            'postal_code'  => staff.xpath('code'          ).text 
            }
          }
        hash
      end
      
    end
  end
end
