platform :ios, '15.0'
use_frameworks!

workspace 'RestaurantFinder'
project 'RestaurantFinder.xcodeproj'

target 'AjiTakl' do
  pod 'GooglePlaces'
  pod 'GoogleMaps'
  
  # Disable code stripping for debug builds
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        if config.name == 'Debug'
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO'
        end
      end
    end
  end
end 