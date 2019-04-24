#!/usr/bin/ruby
#
class SERIALIZABLE
end

class XcodeSchemeModel < SERIALIZABLE
  attr_reader :LastUpgradeVersion, :version, :BuildAction, :TestAction

  def initialize(lastUpgradeVersion, version, buildAction, testActions)
    @LastUpgradeVersion = lastUpgradeVersion
    @version = version
    @BuildAction = XSBuildAction.new(buildAction["parallelizeBuildables"],
                                     buildAction['buildImplicitDependencies'],
                                     buildAction["BuildActionEntries"])
    @TestAction = XSTestAction.new(testActions["Testables"],
                                   testActions["MacroExpansion"],
                                   testActions["AdditionalOptions"],
                                   testActions["buildConfiguration"],
                                   testActions["selectedDebuggerIdentifier"],
                                   testActions["selectedLauncherIdentifier"],
                                   testActions["codeCoverageEnabled"],
                                   testActions["shouldUseLaunchSchemeArgsEnv"])
  end
end

class XSBuildAction < SERIALIZABLE
  attr_reader :parallelizeBuildables, :buildImplicitDependencies, :BuildActionEntries

  def initialize(parallelizeBuildables, buildImplicitDependencies, buildActionEntries)
    @parallelizeBuildables = parallelizeBuildables
    @buildImplicitDependencies = buildImplicitDependencies
    build_entry = buildActionEntries['BuildActionEntry'] unless buildActionEntries.nil? || !buildActionEntries.key?('BuildActionEntry')
    unless build_entry.nil? || build_entry.empty?
      @BuildActionEntries = XSBuildActionEntry.new(build_entry["buildForTesting"],
                                                   build_entry["buildForRunning"],
                                                   build_entry["buildForProfiling"],
                                                   build_entry["buildForArchiving"],
                                                   build_entry["buildForAnalyzing"],
                                                   build_entry["BuildableReference"])
    end
  end
end

class XSBuildActionEntry < SERIALIZABLE
  attr_reader :buildForTesting,
                :buildForRunning,
                :buildForProfiling,
                :buildForArchiving,
                :buildForAnalyzing,
                :BuildableReference

  def initialize(build_for_testing, build_for_running,
                 build_for_profiling, build_for_archiving,
                 build_for_analyzing, buildable_reference)
    @buildForTesting = build_for_testing
    @buildForRunning = build_for_running
    @buildForProfiling = build_for_profiling
    @buildForArchiving = build_for_archiving
    @buildForAnalyzing = build_for_analyzing
    unless buildable_reference.nil?
      @BuildableReference = XSBuildableReference.new(buildable_reference["BuildableIdentifier"],
                                                     buildable_reference["BlueprintIdentifier"],
                                                     buildable_reference["BuildableName"],
                                                     buildable_reference["BlueprintName"],
                                                     buildable_reference["ReferencedContainer"])
    end
  end
end

class XSBuildableReference < SERIALIZABLE
  attr_reader :BuildableIdentifier,
                :BlueprintIdentifier,
                :BuildableName,
                :BlueprintName,
                :ReferencedContainer

  def initialize(buildable_identifier, blueprint_identifier, buildable_name, blueprint_name, reference_container)
    @BuildableIdentifier = buildable_identifier
    @BlueprintIdentifier = blueprint_identifier
    @BuildableName = buildable_name
    @BlueprintName = blueprint_name
    @ReferencedContainer = reference_container
  end
end

class XSTestAction < SERIALIZABLE
  attr_reader :Testables,
                :MacroExpansion,
                :AdditionalOptions,
                :buildConfiguration,
                :selectedDebuggerIdentifier,
                :selectedLauncherIdentifier,
                :codeCoverageEnabled,
                :shouldUseLaunchSchemeArgsEnv

  def initialize(testables,
                 macroExpansion,
                 additionalOptions,
                 buildConfiguration,
                 selectedDebuggerIdentifier,
                 selectedLauncherIdentifier,
                 codeCoverageEnabled,
                 shouldUseLaunchSchemeArgsEnv)

    unless testables.nil? || !testables.key?('TestableReference')
      testables_data = testables["TestableReference"]
      @Testables = XSTestableReference.new(testables_data["BuildableReference"],
                                           testables_data["skipped"],
                                           testables_data["testExecutionOrdering"])
    end
    @MacroExpansion = XSMacroExpansion.new(macroExpansion["BuildableReference"]) unless macroExpansion.nil? || !macroExpansion.key?('BuildableReference')
    @AdditionalOptions = additionalOptions
    @buildConfiguration = buildConfiguration
    @selectedDebuggerIdentifier = selectedDebuggerIdentifier
    @selectedLauncherIdentifier = selectedLauncherIdentifier
    @codeCoverageEnabled = codeCoverageEnabled
    @shouldUseLaunchSchemeArgsEnv = shouldUseLaunchSchemeArgsEnv
  end
end

class XSTestableReference < SERIALIZABLE
  attr_reader :BuildableReference, :skipped, :testExecutionOrdering

  def initialize(buildableReference, skipped, testExecutionOrdering)
    @BuildableReference = XSBuildableReference.new(buildableReference["BuildableIdentifier"],
                                                   buildableReference["BlueprintIdentifier"],
                                                   buildableReference["BuildableName"],
                                                   buildableReference["BlueprintName"],
                                                   buildableReference["ReferencedContainer"])
    @skipped = skipped
    @testExecutionOrdering = testExecutionOrdering
  end
end

class XSMacroExpansion < SERIALIZABLE
  attr_reader :BuildableReference

  def initialize(testableReference)
    @BuildableReference = XSBuildableReference.new(
        testableReference["BuildableIdentifier"],
        testableReference["BlueprintIdentifier"],
        testableReference["BuildableName"],
        testableReference["BlueprintName"],
        testableReference["ReferencedContainer"]
    )
  end
end
