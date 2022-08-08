# frozen_string_literal: true

# This file is generated by running `rake :generate_error_codes`
# Do not manually modify this file
# Generated at: 2018-09-18 18:28:58 UTC
#
module Ably
  module Exceptions
    module Codes
      NO_ERROR = 10_000
      BAD_REQUEST = 40_000
      INVALID_REQUEST_BODY = 40_001
      INVALID_PARAMETER_NAME = 40_002
      INVALID_PARAMETER_VALUE = 40_003
      INVALID_HEADER = 40_004
      INVALID_CREDENTIAL = 40_005
      INVALID_CONNECTION_ID = 40_006
      INVALID_MESSAGE_ID = 40_007
      INVALID_CONTENT_LENGTH = 40_008
      MAXIMUM_MESSAGE_LENGTH_EXCEEDED = 40_009
      INVALID_CHANNEL_NAME = 40_010
      STALE_RING_STATE = 40_011
      INVALID_CLIENT_ID = 40_012
      INVALID_MESSAGE_DATA_OR_ENCODING = 40_013
      RESOURCE_DISPOSED = 40_014
      INVALID_DEVICE_ID = 40_015
      BATCH_ERROR = 40_020
      INVALID_PUBLISH_REQUEST_UNSPECIFIED = 40_030
      INVALID_PUBLISH_REQUEST_INVALID_CLIENTSPECIFIED_ID = 40_031
      UNAUTHORIZED = 40_100
      INVALID_CREDENTIALS = 40_101
      INCOMPATIBLE_CREDENTIALS = 40_102
      INVALID_USE_OF_BASIC_AUTH_OVER_NONTLS_TRANSPORT = 40_103
      TIMESTAMP_NOT_CURRENT = 40_104
      NONCE_VALUE_REPLAYED = 40_105
      UNABLE_TO_OBTAIN_CREDENTIALS_FROM_GIVEN_PARAMETERS = 40_106
      ACCOUNT_DISABLED = 40_110
      ACCOUNT_RESTRICTED_CONNECTION_LIMITS_EXCEEDED = 40_111
      ACCOUNT_BLOCKED_MESSAGE_LIMITS_EXCEEDED = 40_112
      ACCOUNT_BLOCKED = 40_113
      ACCOUNT_RESTRICTED_CHANNEL_LIMITS_EXCEEDED = 40_114
      APPLICATION_DISABLED = 40_120
      KEY_ERROR_UNSPECIFIED = 40_130
      KEY_REVOKED = 40_131
      KEY_EXPIRED = 40_132
      KEY_DISABLED = 40_133
      TOKEN_ERROR_UNSPECIFIED = 40_140
      TOKEN_REVOKED = 40_141
      TOKEN_EXPIRED = 40_142
      TOKEN_UNRECOGNISED = 40_143
      INVALID_JWT_FORMAT = 40_144
      INVALID_TOKEN_FORMAT = 40_145
      CONNECTION_BLOCKED_LIMITS_EXCEEDED = 40_150
      OPERATION_NOT_PERMITTED_WITH_PROVIDED_CAPABILITY = 40_160
      ERROR_FROM_CLIENT_TOKEN_CALLBACK = 40_170
      FORBIDDEN = 40_300
      ACCOUNT_DOES_NOT_PERMIT_TLS_CONNECTION = 40_310
      OPERATION_REQUIRES_TLS_CONNECTION = 40_311
      APPLICATION_REQUIRES_AUTHENTICATION = 40_320
      UNABLE_TO_ACTIVATE_ACCOUNT_DUE_TO_PLACEMENT_CONSTRAINT_UNSPECIFIED = 40_330
      UNABLE_TO_ACTIVATE_ACCOUNT_DUE_TO_PLACEMENT_CONSTRAINT_INCOMPATIBLE_ENVIRONMENT = 40_331
      UNABLE_TO_ACTIVATE_ACCOUNT_DUE_TO_PLACEMENT_CONSTRAINT_INCOMPATIBLE_SITE = 40_332
      NOT_FOUND = 40_400
      METHOD_NOT_ALLOWED = 40_500
      RATE_LIMIT_EXCEEDED_NONFATAL_REQUEST_REJECTED_UNSPECIFIED = 42_910
      MAX_PERCONNECTION_PUBLISH_RATE_LIMIT_EXCEEDED_NONFATAL_UNABLE_TO_PUBLISH_MESSAGE = 42_911
      RATE_LIMIT_EXCEEDED_FATAL = 42_920
      MAX_PERCONNECTION_PUBLISH_RATE_LIMIT_EXCEEDED_FATAL_CLOSING_CONNECTION = 42_921
      INTERNAL_ERROR = 50_000
      INTERNAL_CHANNEL_ERROR = 50_001
      INTERNAL_CONNECTION_ERROR = 50_002
      TIMEOUT_ERROR = 50_003
      REQUEST_FAILED_DUE_TO_OVERLOADED_INSTANCE = 50_004
      REACTOR_OPERATION_FAILED = 70_000
      REACTOR_OPERATION_FAILED_POST_OPERATION_FAILED = 70_001
      REACTOR_OPERATION_FAILED_POST_OPERATION_RETURNED_UNEXPECTED_CODE = 70_002
      REACTOR_OPERATION_FAILED_MAXIMUM_NUMBER_OF_CONCURRENT_INFLIGHT_REQUESTS_EXCEEDED = 70_003
      EXCHANGE_ERROR_UNSPECIFIED = 71_000
      FORCED_REATTACHMENT_DUE_TO_PERMISSIONS_CHANGE = 71_001
      EXCHANGE_PUBLISHER_ERROR_UNSPECIFIED = 71_100
      NO_SUCH_PUBLISHER = 71_101
      PUBLISHER_NOT_ENABLED_AS_AN_EXCHANGE_PUBLISHER = 71_102
      EXCHANGE_PRODUCT_ERROR_UNSPECIFIED = 71_200
      NO_SUCH_PRODUCT = 71_201
      PRODUCT_DISABLED = 71_202
      NO_SUCH_CHANNEL_IN_THIS_PRODUCT = 71_203
      EXCHANGE_SUBSCRIPTION_ERROR_UNSPECIFIED = 71_300
      SUBSCRIPTION_DISABLED = 71_301
      REQUESTER_HAS_NO_SUBSCRIPTION_TO_THIS_PRODUCT = 71_302
      CONNECTION_FAILED = 80_000
      CONNECTION_FAILED_NO_COMPATIBLE_TRANSPORT = 80_001
      CONNECTION_SUSPENDED = 80_002
      DISCONNECTED = 80_003
      ALREADY_CONNECTED = 80_004
      INVALID_CONNECTION_ID_REMOTE_NOT_FOUND = 80_005
      UNABLE_TO_RECOVER_CONNECTION_MESSAGES_EXPIRED = 80_006
      UNABLE_TO_RECOVER_CONNECTION_MESSAGE_LIMIT_EXCEEDED = 80_007
      UNABLE_TO_RECOVER_CONNECTION_CONNECTION_EXPIRED = 80_008
      CONNECTION_NOT_ESTABLISHED_NO_TRANSPORT_HANDLE = 80_009
      INVALID_OPERATION_INVALID_TRANSPORT_HANDLE = 80_010
      UNABLE_TO_RECOVER_CONNECTION_INCOMPATIBLE_AUTH_PARAMS = 80_011
      UNABLE_TO_RECOVER_CONNECTION_INVALID_OR_UNSPECIFIED_CONNECTION_SERIAL = 80_012
      PROTOCOL_ERROR = 80_013
      CONNECTION_TIMED_OUT = 80_014
      INCOMPATIBLE_CONNECTION_PARAMETERS = 80_015
      OPERATION_ON_SUPERSEDED_TRANSPORT = 80_016
      CONNECTION_CLOSED = 80_017
      INVALID_CONNECTION_ID_INVALID_FORMAT = 80_018
      CLIENT_CONFIGURED_AUTHENTICATION_PROVIDER_REQUEST_FAILED = 80_019
      CONTINUITY_LOSS_DUE_TO_MAXIMUM_SUBSCRIBE_MESSAGE_RATE_EXCEEDED = 80_020
      CLIENT_RESTRICTION_NOT_SATISFIED = 80_030
      CHANNEL_OPERATION_FAILED = 90_000
      CHANNEL_OPERATION_FAILED_INVALID_CHANNEL_STATE = 90_001
      CHANNEL_OPERATION_FAILED_EPOCH_EXPIRED_OR_NEVER_EXISTED = 90_002
      UNABLE_TO_RECOVER_CHANNEL_MESSAGES_EXPIRED = 90_003
      UNABLE_TO_RECOVER_CHANNEL_MESSAGE_LIMIT_EXCEEDED = 90_004
      UNABLE_TO_RECOVER_CHANNEL_NO_MATCHING_EPOCH = 90_005
      UNABLE_TO_RECOVER_CHANNEL_UNBOUNDED_REQUEST = 90_006
      CHANNEL_OPERATION_FAILED_NO_RESPONSE_FROM_SERVER = 90_007
      MAXIMUM_NUMBER_OF_CHANNELS_PER_CONNECTION_EXCEEDED = 90_010
      UNABLE_TO_ENTER_PRESENCE_CHANNEL_NO_CLIENTID = 91_000
      UNABLE_TO_ENTER_PRESENCE_CHANNEL_INVALID_CHANNEL_STATE = 91_001
      UNABLE_TO_LEAVE_PRESENCE_CHANNEL_THAT_IS_NOT_ENTERED = 91_002
      UNABLE_TO_ENTER_PRESENCE_CHANNEL_MAXIMUM_MEMBER_LIMIT_EXCEEDED = 91_003
      UNABLE_TO_AUTOMATICALLY_REENTER_PRESENCE_CHANNEL = 91_004
      PRESENCE_STATE_IS_OUT_OF_SYNC = 91_005
      MEMBER_IMPLICITLY_LEFT_PRESENCE_CHANNEL_CONNECTION_CLOSED = 91_100
    end
  end
end
