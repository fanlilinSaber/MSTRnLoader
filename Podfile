# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'MSTRnLoader' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!
# React Native
pod 'React', :path => './node_modules/react-native', :subspecs => [
    'Core',
    'CxxBridge', # 如果RN版本 >= 0.47则加入此行
    'DevSupport', # 如果RN版本 >= 0.43，则需要加入此行才能开启开发者菜单
    'RCTActionSheet',
    'RCTGeolocation',
    'RCTImage',
    'RCTPushNotification',
    'RCTSettings',
    'RCTText',
    'RCTNetwork',
    'RCTVibration',
    'RCTWebSocket', # 调试功能需要此模块
    'RCTAnimation', # FlatList和原生动画功能需要此模块
    'RCTLinkingIOS',
    'RCTCameraRoll',
    'RCTBlob'
  ]
# 如果你的RN版本 >= 0.42.0，则加入下面这行
pod 'yoga', :path => './node_modules/react-native/ReactCommon/yoga'

# 如果RN版本 >= 0.45则加入下面三个第三方编译依赖
pod 'DoubleConversion', :podspec => './node_modules/react-native/third-party-podspecs/DoubleConversion.podspec'
pod 'glog', :podspec => './node_modules/react-native/third-party-podspecs/glog.podspec'
pod 'Folly', :podspec => './node_modules/react-native/third-party-podspecs/Folly.podspec'
# 热修复
pod 'react-native-update' , :path => './node_modules/react-native-update'

pod 'RNGestureHandler' , :podspec => './node_modules/react-native-gesture-handler/RNGestureHandler.podspec'

pod 'react-native-image-picker' , :path => './node_modules/react-native-image-picker'

pod 'RNVectorIcons' , :podspec => './node_modules/react-native-vector-icons/RNVectorIcons.podspec'

pod 'react-native-video' , :podspec => './node_modules/react-native-video/react-native-video.podspec'

pod 'react-native-webview' , :podspec => './node_modules/react-native-webview/react-native-webview.podspec'

  # Pods for MSTRnLoader

end

target 'MSTRnLoader iOS Example' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for MSTRnLoader iOS Example

end
