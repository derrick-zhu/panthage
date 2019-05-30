#!/usr/bin/ruby

module XcodeSDKRoot
  SDK_IPHONEOS = 'iphoneos'
  SDK_IPHONE_SIMULATOR = 'iphonesimulator'
  SDK_TVOS = 'appletvos'
  SDK_MACOSX = 'macosx'
  SDK_WATCHOS = 'watchos'

  def self.type_of(sdk_root)
    case sdk_root
    when SDK_IPHONEOS, SDK_IPHONE_SIMULATOR
      XcodePlatformSDK::FOR_IOS
    when SDK_TVOS
      XcodePlatformSDK::FOR_TVOS
    when SDK_MACOSX
      XcodePlatformSDK::FOR_MACOS
    when SDK_WATCHOS
      XcodePlatformSDK::FOR_WATCHOS
    end
  end

  def self.sdk_root(sdk_type)
    case sdk_type
    when XcodePlatformSDK::FOR_IOS
      [SDK_IPHONEOS, SDK_IPHONE_SIMULATOR]
    when XcodePlatformSDK::FOR_MACOS
      [SDK_MACOSX]
    when XcodePlatformSDK::FOR_TVOS
      [SDK_TVOS]
    when XcodePlatformSDK::FOR_WATCHOS
      [SDK_WATCHOS]
    else
      []
    end
  end
end
