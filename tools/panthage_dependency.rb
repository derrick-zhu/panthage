# frozen_string_literal: true

# PanConstants constants for panthage
class PanConstants
  @@DEBUGING = false

  def self.debuging
    @@DEBUGING
  end

  # dummy fw count (max)
  @@MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE = 10
  def self.max_dummy_template
    @@MAXIMUM_DUMMY_NUMBER_IN_TEMPLATE
  end

  def initialize; end
end

$g_verbose = '--quiet'
$g_verbose = '' if PanConstants.debuging == true

# class panthage_depend_map
$panda_dep_table = {
  "Panda": [
    'HomeSlice' => { fw_name: 'HomeSlice', xc_path: '' },
    'PCOCheckout' => { fw_name: 'PCOCheckout', xc_path: 'PCOCheckout/Checkout.xcodeproj' },
    'PPDSlice-pdp-ios' => { fw_name: 'PPDSlice-pdp-ios', xc_path: 'PPDSlice-pdp-ios/FPDProductDetailSlice.xcodeproj' },
    'ECommerceAPI' => { fw_name: 'ECommerceAPI' },
    'fabs-ios' => { fw_name: 'Fabs', xc_path: 'fabs-ios/Fabs.xcodeproj' },
    'marketingapi-ios' => { fw_name: 'MarketingAPI', xc_path: 'marketingapi-ios/MarketingAPI.xcodeproj' },
    'PCAContentAPI-ios' => { fw_name: 'ContentAPI', xc_path: 'PCAContentAPI-ios/ContentAPI.xcodeproj' },
    'PPAPaymentsAPI' => { fw_name: 'PaymentsAPI', xc_path: 'PPAPaymentsAPI/PaymentsAPI.xcodeproj' },
    'PCSChannelServiceAPI' => { fw_name: 'ChannelService', xc_path: 'PCSChannelServiceAPI/ChannelService.xcodeproj' },
    'frameworkCMS-ios' => { fw_name: 'FarfetchCMS', xc_path: 'frameworkCMS-ios/FarfetchCMS.xcodeproj' },
    'helpers-ios' => { fw_name: 'LegacyHelper', xc_path: 'helpers-ios/LegacyHelper.xcodeproj' },
    'managers-ios' => { fw_name: 'LegacyManager', xc_path: 'managers-ios/LegacyManager.xcodeproj' },
    'panda-ui-ios' => { fw_name: 'DiscoverUI', xc_path: 'panda-ui-ios/DiscoverUI.xcodeproj' },
    'panda-kit-ios' => { fw_name: 'LegacyPandaKit', xc_path: 'panda-kit-ios/LegacyPandaKit.xcodeproj' },
    'RuleSystem' => { fw_name: 'RuleSystem', xc_path: 'RuleSystem/RuleSystem.xcodeproj' },
    'FNMNetworkMonitor' => { fw_name: 'FFNetworkMonitor', xc_path: 'FNMNetworkMonitor/NetworkMonitor.xcodeproj' },
    'PDFoundation' => { fw_name: 'PDFoundation', xc_path: 'PDFoundation/PDFoundation.xcodeproj' },
    'PDAppKit' => { fw_name: 'PDAppKit', xc_path: 'PDAppKit/PDAppKit.xcodeproj' },
    'PandaService' => { fw_name: 'PandaService', xc_path: 'PandaService/PandaService.xcodeproj' },
    'SocialSDK' => { fw_name: 'SocialSDK', xc_path: 'SocialSDK/SocialSDK.xcodeproj' },
    'alipay-ios' => { fw_name: 'FFAliPay', xc_path: 'alipay-ios/FFAliPay.xcodeproj' },
    'wechat-ios' => { fw_name: 'wechat-ios', xc_path: 'wechat-ios/FFWeChat.xcodeproj' },
    'unionpay-ios' => { fw_name: 'unionpay-ios', xc_path: 'unionpay-ios/FFUnionPay.xcodeproj' },
    'FFCardIO' => { fw_name: 'FFCardIO', xc_path: 'FFCardIO/FFCardIO.xcodeproj' },
    'BlackDragon' => { fw_name: 'BlackDragon', xc_path: 'BlackDragon/BlackDragon.xcodeproj' },
    'certona-ios' => { fw_name: 'certona-ios', xc_path: 'certona-ios/Certona.xcodeproj' },
    'RelevantBrands' => { fw_name: 'RelevantBrands', xc_path: 'RelevantBrands/RelevantBrands.xcodeproj' },
    'OmniTracking' => { fw_name: 'OmniTracking', xc_path: 'OmniTracking/OmniTracking.xcodeproj' }
  ]
}

# main command
CMD_UNKNOW = -1
CMD_INSTALL = CMD_UNKNOW + 1
CMD_UPDATE = CMD_INSTALL + 1
CMD_BOOTSTRAP = CMD_UPDATE + 1

def command_install?(cmd)
  cmd == CMD_INSTALL
end

def command_update?(cmd)
  cmd == CMD_UPDATE
end

def command_bootstrap?(cmd)
  cmd == CMD_BOOTSTRAP
end

module GitRepoType
  UNKNOWN = -1
  TAG = 0
  BRANCH = TAG + 1
end

