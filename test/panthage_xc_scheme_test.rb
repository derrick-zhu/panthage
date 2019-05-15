require 'test/unit'
require 'json'
require 'crack'
require 'rubygems'
require_relative '../tools/models/roj/panthage_xc_scheme_model'
require_relative '../tools/utils/panthage_xml'

class TestXcodeScheme < Test::Unit::TestCase
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test_load_build_action
    xml_sample = %(
    <?xml version="1.0" encoding="UTF-8"?>
    <Scheme
       LastUpgradeVersion = "1020"
       version = "1.3">
       <BuildAction
          parallelizeBuildables = "YES"
          buildImplicitDependencies = "YES">
          <BuildActionEntries>
             <BuildActionEntry
                buildForTesting = "YES"
                buildForRunning = "YES"
                buildForProfiling = "YES"
                buildForArchiving = "YES"
                buildForAnalyzing = "YES">
                <BuildableReference
                   BuildableIdentifier = "primary"
                   BlueprintIdentifier = "D1ED2D341AD2D09F00CFC3EB"
                   BuildableName = "Kingfisher.framework"
                   BlueprintName = "Kingfisher-iOS"
                   ReferencedContainer = "container:Kingfisher.xcodeproj">
                </BuildableReference>
             </BuildActionEntry>
          </BuildActionEntries>
       </BuildAction>
       <TestAction
          buildConfiguration = "Debug"
          selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
          selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
          codeCoverageEnabled = "YES"
          shouldUseLaunchSchemeArgsEnv = "YES">
          <Testables>
             <TestableReference
                skipped = "NO"
                testExecutionOrdering = "random">
                <BuildableReference
                   BuildableIdentifier = "primary"
                   BlueprintIdentifier = "D1ED2D3E1AD2D09F00CFC3EB"
                   BuildableName = "KingfisherTests.xctest"
                   BlueprintName = "KingfisherTests"
                   ReferencedContainer = "container:Kingfisher.xcodeproj">
                </BuildableReference>
             </TestableReference>
          </Testables>
          <MacroExpansion>
             <BuildableReference
                BuildableIdentifier = "primary"
                BlueprintIdentifier = "D1ED2D341AD2D09F00CFC3EB"
                BuildableName = "Kingfisher.framework"
                BlueprintName = "Kingfisher-iOS"
                ReferencedContainer = "container:Kingfisher.xcodeproj">
             </BuildableReference>
          </MacroExpansion>
          <AdditionalOptions>
          </AdditionalOptions>
       </TestAction>
    </Scheme>
    )
    scheme_data = XMLUtils::to_json(xml_sample)["Scheme"]
    schemes = XcodeSchemeModel.new(scheme_data['LastUpgradeVersion'],
                                   scheme_data['version'],
                                   scheme_data['BuildAction'],
                                   scheme_data['TestAction'])

    assert(!schemes.nil?)
  end
end