# Ably is the base namespace for the Ably {Ably::Realtime Realtime} & {Ably::Rest Rest} client libraries.
#
# Please refer to the {file:README.md Readme} on getting started.
#
# @see file:README.md README
module Ably
  # Fallback hosts to use when a connection to rest/realtime.ably.io is not possible due to
  # network failures either at the client, between the client and Ably, within an Ably data center, or at the IO domain registrar
  #
  FALLBACK_HOSTS = %w(A.ably-realtime.com B.ably-realtime.com C.ably-realtime.com D.ably-realtime.com E.ably-realtime.com).freeze

  INTERNET_CHECK = {
    url:     '//internet-up.ably-realtime.com/is-the-internet-up.txt',
    ok_text: 'yes'
  }.freeze
end
