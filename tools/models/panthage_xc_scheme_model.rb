#!/usr/bin/ruby
#

require 'json'
require 'json_mapper'
require 'rubygems'
require 'date'

class XSBuildableReference
  include JSONMapper

  json_attribute :BuildableIdentifier, String
  json_attribute :BlueprintIdentifier, String
  json_attribute :BuildableName, String
  json_attribute :BlueprintName, String
  json_attribute :ReferencedContainer, String
end

class XSBuildActionEntry
  include JSONMapper

  json_attribute :buildForTesting, String
  json_attribute :buildForRunning, String
  json_attribute :buildForProfiling, String
  json_attribute :buildForArchiving, String
  json_attribute :buildForAnalyzing, String
  json_attribute :BuildableReference, XSBuildableReference
end

class XSBuildActionEntries
  include JSONMapper

  json_attributes :BuildActionEntry, XSBuildActionEntry
end

class XSBuildAction
  include JSONMapper

  json_attribute :parallelizeBuildables, String
  json_attribute :buildImplicitDependencies, String
  json_attribute :BuildActionEntries, XSBuildActionEntries
end

class XSTestableReference
  include JSONMapper

  json_attribute :BuildableReference, XSBuildableReference
  json_attribute :skipped, String
  json_attribute :testExecutionOrdering, String
end

class XSMacroExpansion
  include JSONMapper

  json_attribute :BuildableReference, XSBuildableReference
end

class XSTestAction
  include JSONMapper

  json_attribute :Testables, XSTestableReference
  json_attribute :MacroExpansion, XSMacroExpansion
  json_attribute :AdditionalOptions, String
  json_attribute :buildConfiguration, String
  json_attribute :selectedDebuggerIdentifier, String
  json_attribute :selectedLauncherIdentifier, String
  json_attribute :codeCoverageEnabled, String
  json_attribute :shouldUseLaunchSchemeArgsEnv, String
end

class XcodeSchemeModel
  include JSONMapper

  json_attribute :LastUpgradeVersion, String
  json_attribute :version, String
  json_attribute :BuildAction, XSBuildAction
  json_attribute :TestAction, XSTestAction
end

class XcodeSchemeEntryModel
  include JSONMapper

  attr_accessor :name

  json_attribute :Scheme, XcodeSchemeModel
end
