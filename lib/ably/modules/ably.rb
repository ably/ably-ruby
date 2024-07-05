# Ably is the base namespace for the Ably {Ably::Realtime Realtime} & {Ably::Rest Rest} client libraries.
#
# Please refer to the {file:README.md Readme} on getting started.
#
# @see file:README.md README
module Ably
  # Fallback hosts to use when a connection to rest/realtime.ably.io is not possible due to
  # network failures either at the client, between the client and Ably, within an Ably data center, or at the IO domain registrar
  # see https://ably.com/docs/client-lib-development-guide/features/#RSC15a
  #
  FALLBACK_DOMAIN = 'ably-realtime-nonprod.com'.freeze
  FALLBACK_IDS = %w(a b c d e).freeze

  # Default production fallbacks a.ably-realtime.com ... e.ably-realtime.com
  FALLBACK_HOSTS = FALLBACK_IDS.map { |host| "#{host}.#{FALLBACK_DOMAIN}".freeze }.freeze

  # Custom environment default fallbacks {ENV}-a-fallback.ably-realtime.com ... {ENV}-a-fallback.ably-realtime.com
  CUSTOM_ENVIRONMENT_FALLBACKS_SUFFIXES = FALLBACK_IDS.map do |host|
    "-#{host}-fallback.#{FALLBACK_DOMAIN}".freeze
  end.freeze

  INTERNET_CHECK = {
    url:     '//internet-up.ably-realtime.com/is-the-internet-up.txt',
    ok_text: 'yes'
  }.freeze
end
