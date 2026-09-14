#!/usr/bin/env ruby

require "pathname"

ROOT = Pathname.new(File.expand_path("..", __dir__))
SOURCE_ROOT = ROOT.join("GlassReader")
PROJECT_FILE = ROOT.join("GlassReader.xcodeproj/project.pbxproj")
SCHEME_FILE = ROOT.join("GlassReader.xcodeproj/xcshareddata/xcschemes/GlassReader.xcscheme")

class IDs
  def initialize
    @value = 0
  end

  def next
    @value += 1
    format("B%023X", @value)
  end
end

ids = IDs.new
swift_files = Dir.glob(SOURCE_ROOT.join("**/*.swift")).sort.map { |path| Pathname.new(path).relative_path_from(ROOT).to_s }
resource_files = ["GlassReader/Resources/AppIcon.icns", "GlassReader/Resources/AppIcon.png"]

file_ids = (swift_files + resource_files).to_h { |path| [path, ids.next] }
tools_id = ids.next
info_id = ids.next
product_id = ids.next
build_ids = (swift_files + resource_files + ["GlassReader/Resources/Tools"]).to_h { |path| [path, ids.next] }

directories = swift_files.flat_map do |path|
  directory = Pathname.new(File.dirname(path))
  ancestors = []
  loop do
    value = directory.to_s
    break unless value == "GlassReader" || value.start_with?("GlassReader/")
    ancestors << value
    break if value == "GlassReader"
    directory = directory.parent
  end
  ancestors
end
directories += %w[GlassReader GlassReader/Resources]
directories = directories.uniq.sort
group_ids = directories.to_h { |path| [path, ids.next] }
config_group_id = ids.next
products_group_id = ids.next
main_group_id = ids.next
sources_phase_id = ids.next
frameworks_phase_id = ids.next
resources_phase_id = ids.next
target_id = ids.next
project_id = ids.next
project_debug_id = ids.next
project_release_id = ids.next
target_debug_id = ids.next
target_release_id = ids.next
project_config_list_id = ids.next
target_config_list_id = ids.next

lines = []
lines << '// !$*UTF8*$!'
lines << '{'
lines << "\tarchiveVersion = 1;"
lines << "\tclasses = {};"
lines << "\tobjectVersion = 56;"
lines << "\tobjects = {"
lines << ''
lines << '/* Begin PBXBuildFile section */'
swift_files.each { |path| lines << "\t\t#{build_ids[path]} /* #{File.basename(path)} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ids[path]} /* #{File.basename(path)} */; };" }
resource_files.each { |path| lines << "\t\t#{build_ids[path]} /* #{File.basename(path)} in Resources */ = {isa = PBXBuildFile; fileRef = #{file_ids[path]} /* #{File.basename(path)} */; };" }
lines << "\t\t#{build_ids['GlassReader/Resources/Tools']} /* Tools in Resources */ = {isa = PBXBuildFile; fileRef = #{tools_id} /* Tools */; };"
lines << '/* End PBXBuildFile section */'
lines << ''
lines << '/* Begin PBXFileReference section */'
swift_files.each { |path| lines << "\t\t#{file_ids[path]} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{File.basename(path).inspect}; sourceTree = \"<group>\"; };" }
lines << "\t\t#{file_ids[resource_files[0]]} /* AppIcon.icns */ = {isa = PBXFileReference; lastKnownFileType = image.icns; path = AppIcon.icns; sourceTree = \"<group>\"; };"
lines << "\t\t#{file_ids[resource_files[1]]} /* AppIcon.png */ = {isa = PBXFileReference; lastKnownFileType = image.png; path = AppIcon.png; sourceTree = \"<group>\"; };"
lines << "\t\t#{tools_id} /* Tools */ = {isa = PBXFileReference; lastKnownFileType = folder; path = Tools; sourceTree = \"<group>\"; };"
lines << "\t\t#{info_id} /* GlassReader-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"GlassReader-Info.plist\"; sourceTree = \"<group>\"; };"
lines << "\t\t#{product_id} /* GlassReader.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GlassReader.app; sourceTree = BUILT_PRODUCTS_DIR; };"
lines << '/* End PBXFileReference section */'
lines << ''
lines << '/* Begin PBXFrameworksBuildPhase section */'
lines << "\t\t#{frameworks_phase_id} /* Frameworks */ = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };"
lines << '/* End PBXFrameworksBuildPhase section */'
lines << ''
lines << '/* Begin PBXGroup section */'
directories.each do |directory|
  direct_directories = directories.select { |candidate| File.dirname(candidate) == directory }
  direct_files = swift_files.select { |path| File.dirname(path) == directory }
  children = direct_directories.map { |path| "#{group_ids[path]} /* #{File.basename(path)} */" }
  children += direct_files.map { |path| "#{file_ids[path]} /* #{File.basename(path)} */" }
  if directory == "GlassReader/Resources"
    children += resource_files.map { |path| "#{file_ids[path]} /* #{File.basename(path)} */" }
    children << "#{tools_id} /* Tools */"
  end
  lines << "\t\t#{group_ids[directory]} /* #{File.basename(directory)} */ = {"
  lines << "\t\t\tisa = PBXGroup;"
  lines << "\t\t\tchildren = ("
  children.each { |child| lines << "\t\t\t\t#{child}," }
  lines << "\t\t\t);"
  lines << "\t\t\tpath = #{File.basename(directory).inspect};"
  lines << "\t\t\tsourceTree = \"<group>\";"
  lines << "\t\t};"
end
lines << "\t\t#{config_group_id} /* Config */ = {isa = PBXGroup; children = (#{info_id} /* GlassReader-Info.plist */); path = Config; sourceTree = \"<group>\"; };"
lines << "\t\t#{products_group_id} /* Products */ = {isa = PBXGroup; children = (#{product_id} /* GlassReader.app */); name = Products; sourceTree = \"<group>\"; };"
lines << "\t\t#{main_group_id} = {isa = PBXGroup; children = (#{group_ids['GlassReader']} /* GlassReader */, #{config_group_id} /* Config */, #{products_group_id} /* Products */); sourceTree = \"<group>\"; };"
lines << '/* End PBXGroup section */'
lines << ''
lines << '/* Begin PBXNativeTarget section */'
lines << "\t\t#{target_id} /* GlassReader */ = {isa = PBXNativeTarget; buildConfigurationList = #{target_config_list_id}; buildPhases = (#{sources_phase_id} /* Sources */, #{frameworks_phase_id} /* Frameworks */, #{resources_phase_id} /* Resources */); buildRules = (); dependencies = (); name = GlassReader; productName = GlassReader; productReference = #{product_id} /* GlassReader.app */; productType = \"com.apple.product-type.application\"; };"
lines << '/* End PBXNativeTarget section */'
lines << ''
lines << '/* Begin PBXProject section */'
lines << "\t\t#{project_id} /* Project object */ = {isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2660; LastUpgradeCheck = 2660; TargetAttributes = {#{target_id} = {CreatedOnToolsVersion = 26.6;};};}; buildConfigurationList = #{project_config_list_id}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = zh_CN; hasScannedForEncodings = 0; knownRegions = (zh_CN, en, Base); mainGroup = #{main_group_id}; productRefGroup = #{products_group_id}; projectDirPath = \"\"; projectRoot = \"\"; targets = (#{target_id} /* GlassReader */); };"
lines << '/* End PBXProject section */'
lines << ''
lines << '/* Begin PBXResourcesBuildPhase section */'
resource_entries = resource_files.map { |path| "#{build_ids[path]} /* #{File.basename(path)} in Resources */" } + ["#{build_ids['GlassReader/Resources/Tools']} /* Tools in Resources */"]
lines << "\t\t#{resources_phase_id} /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (#{resource_entries.join(', ')}); runOnlyForDeploymentPostprocessing = 0; };"
lines << '/* End PBXResourcesBuildPhase section */'
lines << ''
lines << '/* Begin PBXSourcesBuildPhase section */'
source_entries = swift_files.map { |path| "#{build_ids[path]} /* #{File.basename(path)} in Sources */" }
lines << "\t\t#{sources_phase_id} /* Sources */ = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (#{source_entries.join(', ')}); runOnlyForDeploymentPostprocessing = 0; };"
lines << '/* End PBXSourcesBuildPhase section */'
lines << ''
lines << '/* Begin XCBuildConfiguration section */'
lines << "\t\t#{project_debug_id} /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {CLANG_ENABLE_MODULES = YES; MACOSX_DEPLOYMENT_TARGET = 14.0; SDKROOT = macosx; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";}; name = Debug;};"
lines << "\t\t#{project_release_id} /* Release */ = {isa = XCBuildConfiguration; buildSettings = {CLANG_ENABLE_MODULES = YES; MACOSX_DEPLOYMENT_TARGET = 14.0; SDKROOT = macosx; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = \"-O\";}; name = Release;};"
target_settings = 'CODE_SIGN_STYLE = Automatic; COMBINE_HIDPI_IMAGES = YES; CURRENT_PROJECT_VERSION = 21; DEVELOPMENT_TEAM = ""; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = "Config/GlassReader-Info.plist"; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks"; MACOSX_DEPLOYMENT_TARGET = 14.0; MARKETING_VERSION = 0.1.20; PRODUCT_BUNDLE_IDENTIFIER = local.codex.GlassReader; PRODUCT_NAME = GlassReader; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 6.0;'
lines << "\t\t#{target_debug_id} /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {#{target_settings}}; name = Debug;};"
lines << "\t\t#{target_release_id} /* Release */ = {isa = XCBuildConfiguration; buildSettings = {#{target_settings}}; name = Release;};"
lines << '/* End XCBuildConfiguration section */'
lines << ''
lines << '/* Begin XCConfigurationList section */'
lines << "\t\t#{project_config_list_id} = {isa = XCConfigurationList; buildConfigurations = (#{project_debug_id} /* Debug */, #{project_release_id} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;};"
lines << "\t\t#{target_config_list_id} = {isa = XCConfigurationList; buildConfigurations = (#{target_debug_id} /* Debug */, #{target_release_id} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;};"
lines << '/* End XCConfigurationList section */'
lines << "\t};"
lines << "\trootObject = #{project_id} /* Project object */;"
lines << '}'

PROJECT_FILE.write(lines.join("\n") + "\n")

scheme = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <Scheme LastUpgradeVersion="2660" version="1.7">
     <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
        <BuildActionEntries>
           <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
              <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="#{target_id}" BuildableName="GlassReader.app" BlueprintName="GlassReader" ReferencedContainer="container:GlassReader.xcodeproj"/>
           </BuildActionEntry>
        </BuildActionEntries>
     </BuildAction>
     <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
     <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
        <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="#{target_id}" BuildableName="GlassReader.app" BlueprintName="GlassReader" ReferencedContainer="container:GlassReader.xcodeproj"/></BuildableProductRunnable>
     </LaunchAction>
     <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
        <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="#{target_id}" BuildableName="GlassReader.app" BlueprintName="GlassReader" ReferencedContainer="container:GlassReader.xcodeproj"/></BuildableProductRunnable>
     </ProfileAction>
     <AnalyzeAction buildConfiguration="Debug"/>
     <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
  </Scheme>
XML
SCHEME_FILE.dirname.mkpath
SCHEME_FILE.write(scheme)
