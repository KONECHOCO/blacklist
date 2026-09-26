# Adds the Call Directory extension target and the App Group entitlements to the
# Flutter Runner project. Idempotent. Runs on Codemagic before the build:
#   gem install xcodeproj && ruby ios/scripts/add_call_directory.rb
require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
project = Xcodeproj::Project.open(File.join(ROOT, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
runner_group = project.main_group.find_subpath('Runner', false)

# --- Runner: bridge source + entitlements -----------------------------------
unless runner_group.files.any? { |f| f.path == 'ScreeningBridge.swift' }
  ref = runner_group.new_reference('ScreeningBridge.swift')
  runner.source_build_phase.add_file_reference(ref)
end
runner_group.new_reference('Runner.entitlements') unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
runner.add_system_framework('CallKit') unless runner.frameworks_build_phase.files.any? { |f| f.display_name == 'CallKit.framework' }

# --- CallDirectory extension ------------------------------------------------
ext = project.targets.find { |t| t.name == 'CallDirectory' }
unless ext
  ext = project.new_target(:app_extension, 'CallDirectory', :ios, '13.0', nil, :swift)
  group = project.main_group.find_subpath('CallDirectory', true)
  group.set_source_tree('<group>')
  group.set_path('CallDirectory')
  src = group.new_reference('CallDirectoryHandler.swift')
  ext.source_build_phase.add_file_reference(src)
  group.new_reference('Info.plist')
  group.new_reference('CallDirectory.entitlements')
  ext.add_system_framework('CallKit')

  # Embed the .appex into the app.
  embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' } ||
          runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
  build_file = embed.add_file_reference(ext.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  runner.add_dependency(ext)
end

flutter_group = project.main_group.find_subpath('Flutter', false)
xcconfig = flutter_group.files.find { |f| f.path == 'Flutter/Extension.xcconfig' } || flutter_group.new_reference('Flutter/Extension.xcconfig')

ext.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.konechoco.blacklist.CallDirectory'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'CallDirectory/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'CallDirectory/CallDirectory.entitlements'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['CODE_SIGN_STYLE'] = 'Manual'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  # Same Flutter build name/number as the app, without the Pods settings of Release.xcconfig.
  c.base_configuration_reference = xcconfig
end

project.save
puts 'ok: CallDirectory target + App Group entitlements'
