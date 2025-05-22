# Ably is the base namespace for the Ably {Ably::Realtime Realtime} & {Ably::Rest Rest} client libraries.
#
# Please refer to the {file:README.md Readme} on getting started.
#
# @see file:README.md README
module Ably
  # Fallback hosts to use when a connection to main.realtime.ably.net is not possible due to
  # network failures either at the client, between the client and Ably, within an Ably data center, or at the IO domain registrar
  # see https://ably.com/docs/client-lib-development-guide/features/#RSC15a
  #
  PROD_FALLBACK_DOMAIN = 'ably-realtime.com'.freeze
  NONPROD_FALLBACK_DOMAIN = 'ably-realtime-nonprod.com'.freeze

  FALLBACK_IDS = %w(a b c d e).freeze

  # Default production fallbacks main.a.fallback.ably-realtime.com ... main.e.fallback.ably-realtime.com
  FALLBACK_HOSTS = FALLBACK_IDS.map { |host| "main.#{host}.fallback.#{PROD_FALLBACK_DOMAIN}".freeze }.freeze

  # Prod fallback suffixes a.fallback.ably-realtime.com ... e.fallback.ably-realtime.com
  PROD_FALLBACKS_SUFFIXES = FALLBACK_IDS.map do |host|
    "#{host}.fallback.#{PROD_FALLBACK_DOMAIN}".freeze
  end.freeze

  # Nonprod fallback suffixes a.fallback.ably-realtime-nonprod.com ... e.fallback.ably-realtime-nonprod.com
  NONPROD_FALLBACKS_SUFFIXES = FALLBACK_IDS.map do |host|
    "#{host}.fallback.#{NONPROD_FALLBACK_DOMAIN}".freeze
  end.freeze

  INTERNET_CHECK = {
    url:     '//internet-up.ably-realtime.com/is-the-internet-up.txt',
    ok_text: 'yes'
  }.freeze
end
