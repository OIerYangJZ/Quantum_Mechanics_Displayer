import Foundation

struct IDGenerator {
    private var value = 1

    mutating func next() -> String {
        defer { value += 1 }
        return String(format: "%024X", value)
    }
}

struct SourceFile {
    let id: String
    let buildID: String
    let path: String

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let projectDirectory = root.appendingPathComponent("QuantumMechanicsLab.xcodeproj")
let projectFile = projectDirectory.appendingPathComponent("project.pbxproj")
let schemeDirectory = projectDirectory.appendingPathComponent("xcshareddata/xcschemes")
let schemeFile = schemeDirectory.appendingPathComponent("QuantumMechanicsLab.xcscheme")

func swiftFiles(under relativePath: String) throws -> [String] {
    let directory = root.appendingPathComponent(relativePath)
    guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
        return []
    }

    return enumerator
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "swift" }
        .map { url in
            String(url.path.dropFirst(root.path.count + 1))
        }
        .sorted()
}

func quotedList(_ values: [String], indent: String = "\t\t\t\t") -> String {
    values.map { "\(indent)\($0)," }.joined(separator: "\n")
}

func buildSettings(_ values: [(String, String)]) -> String {
    values.map { key, value in "\t\t\t\t\(key) = \(value);" }.joined(separator: "\n")
}

var ids = IDGenerator()

let projectID = ids.next()
let mainGroupID = ids.next()
let productsGroupID = ids.next()
let coreGroupID = ids.next()
let appGroupID = ids.next()
let testsGroupID = ids.next()
let frameworksGroupID = ids.next()

let coreTargetID = ids.next()
let appTargetID = ids.next()
let testsTargetID = ids.next()
let dependencyID = ids.next()
let dependencyProxyID = ids.next()
let testsDependencyID = ids.next()
let testsDependencyProxyID = ids.next()

let coreSourcesPhaseID = ids.next()
let coreFrameworksPhaseID = ids.next()
let coreResourcesPhaseID = ids.next()
let appSourcesPhaseID = ids.next()
let appFrameworksPhaseID = ids.next()
let appResourcesPhaseID = ids.next()
let testsSourcesPhaseID = ids.next()
let testsFrameworksPhaseID = ids.next()
let testsResourcesPhaseID = ids.next()
let appEmbedFrameworksPhaseID = ids.next()

let coreProductID = ids.next()
let appProductID = ids.next()
let testsProductID = ids.next()
let coreFrameworkTestsBuildID = ids.next()
let accelerateFrameworkID = ids.next()
let accelerateBuildID = ids.next()
let coreFrameworkBuildID = ids.next()
let coreFrameworkEmbedID = ids.next()

let projectConfigListID = ids.next()
let projectDebugConfigID = ids.next()
let projectReleaseConfigID = ids.next()
let coreConfigListID = ids.next()
let coreDebugConfigID = ids.next()
let coreReleaseConfigID = ids.next()
let appConfigListID = ids.next()
let appDebugConfigID = ids.next()
let appReleaseConfigID = ids.next()
let testsConfigListID = ids.next()
let testsDebugConfigID = ids.next()
let testsReleaseConfigID = ids.next()

let coreSources = try swiftFiles(under: "Sources/QuantumMechanicsLabCore").map {
    SourceFile(id: ids.next(), buildID: ids.next(), path: $0)
}

let testsSources = try swiftFiles(under: "Tests/QuantumMechanicsLabCoreTests").map { SourceFile(id: ids.next(), buildID: ids.next(), path: $0) }

let appSources = try swiftFiles(under: "Sources/QuantumMechanicsLabApp").map {
    SourceFile(id: ids.next(), buildID: ids.next(), path: $0)
}

let projectDebugSettings = buildSettings([
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("CLANG_ANALYZER_NONNULL", "YES"),
    ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
    ("CLANG_CXX_LANGUAGE_STANDARD", "\"gnu++20\""),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("CLANG_ENABLE_OBJC_WEAK", "YES"),
    ("CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING", "YES"),
    ("CLANG_WARN_BOOL_CONVERSION", "YES"),
    ("CLANG_WARN_COMMA", "YES"),
    ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
    ("CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS", "YES"),
    ("CLANG_WARN_DIRECT_OBJC_ISA_USAGE", "YES_ERROR"),
    ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
    ("CLANG_WARN_EMPTY_BODY", "YES"),
    ("CLANG_WARN_ENUM_CONVERSION", "YES"),
    ("CLANG_WARN_INFINITE_RECURSION", "YES"),
    ("CLANG_WARN_INT_CONVERSION", "YES"),
    ("CLANG_WARN_NON_LITERAL_NULL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF", "YES"),
    ("CLANG_WARN_OBJC_LITERAL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_ROOT_CLASS", "YES_ERROR"),
    ("CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER", "YES"),
    ("CLANG_WARN_RANGE_LOOP_ANALYSIS", "YES"),
    ("CLANG_WARN_STRICT_PROTOTYPES", "YES"),
    ("CLANG_WARN_SUSPICIOUS_MOVE", "YES"),
    ("CLANG_WARN_UNGUARDED_AVAILABILITY", "YES_AGGRESSIVE"),
    ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
    ("CLANG_WARN__DUPLICATE_METHOD_MATCH", "YES"),
    ("COPY_PHASE_STRIP", "NO"),
    ("DEBUG_INFORMATION_FORMAT", "dwarf"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("ENABLE_TESTABILITY", "YES"),
    ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
    ("GCC_DYNAMIC_NO_PIC", "NO"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("GCC_OPTIMIZATION_LEVEL", "0"),
    ("GCC_PREPROCESSOR_DEFINITIONS", "(\"DEBUG=1\", \"$(inherited)\")"),
    ("GCC_WARN_64_TO_32_BIT_CONVERSION", "YES"),
    ("GCC_WARN_ABOUT_RETURN_TYPE", "YES_ERROR"),
    ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION", "YES"),
    ("GCC_WARN_UNUSED_VARIABLE", "YES"),
    ("IPHONEOS_DEPLOYMENT_TARGET", "18.0"),
    ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "DEBUG"),
    ("SWIFT_OPTIMIZATION_LEVEL", "\"-Onone\""),
    ("SWIFT_VERSION", "6.0"),
    ("TARGETED_DEVICE_FAMILY", "2")
])

let projectReleaseSettings = buildSettings([
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("CLANG_ANALYZER_NONNULL", "YES"),
    ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
    ("CLANG_CXX_LANGUAGE_STANDARD", "\"gnu++20\""),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("CLANG_ENABLE_OBJC_WEAK", "YES"),
    ("CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING", "YES"),
    ("CLANG_WARN_BOOL_CONVERSION", "YES"),
    ("CLANG_WARN_COMMA", "YES"),
    ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
    ("CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS", "YES"),
    ("CLANG_WARN_DIRECT_OBJC_ISA_USAGE", "YES_ERROR"),
    ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
    ("CLANG_WARN_EMPTY_BODY", "YES"),
    ("CLANG_WARN_ENUM_CONVERSION", "YES"),
    ("CLANG_WARN_INFINITE_RECURSION", "YES"),
    ("CLANG_WARN_INT_CONVERSION", "YES"),
    ("CLANG_WARN_NON_LITERAL_NULL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF", "YES"),
    ("CLANG_WARN_OBJC_LITERAL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_ROOT_CLASS", "YES_ERROR"),
    ("CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER", "YES"),
    ("CLANG_WARN_RANGE_LOOP_ANALYSIS", "YES"),
    ("CLANG_WARN_STRICT_PROTOTYPES", "YES"),
    ("CLANG_WARN_SUSPICIOUS_MOVE", "YES"),
    ("CLANG_WARN_UNGUARDED_AVAILABILITY", "YES_AGGRESSIVE"),
    ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
    ("CLANG_WARN__DUPLICATE_METHOD_MATCH", "YES"),
    ("COPY_PHASE_STRIP", "NO"),
    ("DEBUG_INFORMATION_FORMAT", "\"dwarf-with-dsym\""),
    ("ENABLE_NS_ASSERTIONS", "NO"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("GCC_WARN_64_TO_32_BIT_CONVERSION", "YES"),
    ("GCC_WARN_ABOUT_RETURN_TYPE", "YES_ERROR"),
    ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION", "YES"),
    ("GCC_WARN_UNUSED_VARIABLE", "YES"),
    ("IPHONEOS_DEPLOYMENT_TARGET", "18.0"),
    ("MTL_ENABLE_DEBUG_INFO", "NO"),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_COMPILATION_MODE", "wholemodule"),
    ("SWIFT_OPTIMIZATION_LEVEL", "\"-O\""),
    ("SWIFT_VERSION", "6.0"),
    ("TARGETED_DEVICE_FAMILY", "2"),
    ("VALIDATE_PRODUCT", "YES")
])

let coreTargetSettings = buildSettings([
    ("DEFINES_MODULE", "YES"),
    ("DYLIB_COMPATIBILITY_VERSION", "1"),
    ("DYLIB_CURRENT_VERSION", "1"),
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("INFOPLIST_KEY_CFBundleDisplayName", "QuantumMechanicsLabCore"),
    ("INSTALL_PATH", "\"@rpath\""),
    ("PRODUCT_BUNDLE_IDENTIFIER", "io.github.oieryangjz.quantummechanicslab.core"),
    ("PRODUCT_NAME", "\"$(TARGET_NAME)\""),
    ("SKIP_INSTALL", "YES"),
    ("SUPPORTED_PLATFORMS", "\"iphoneos iphonesimulator\""),
    ("SUPPORTS_MACCATALYST", "NO"),
    ("SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD", "NO"),
    ("SWIFT_VERSION", "6.0"),
    ("TARGETED_DEVICE_FAMILY", "2")
])

let appTargetSettings = buildSettings([
    ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
    ("CODE_SIGN_STYLE", "Automatic"),
    ("CURRENT_PROJECT_VERSION", "1"),
    ("GENERATE_INFOPLIST_FILE", "YES"),
    ("INFOPLIST_KEY_CFBundleDisplayName", "\"Quantum Mechanics Lab\""),
    ("INFOPLIST_KEY_LSApplicationCategoryType", "\"public.app-category.education\""),
    ("INFOPLIST_KEY_UIApplicationSceneManifest_Generation", "YES"),
    ("INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents", "YES"),
    ("INFOPLIST_KEY_UILaunchScreen_Generation", "YES"),
    ("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad", "\"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\""),
    ("MARKETING_VERSION", "0.1.0"),
    ("PRODUCT_BUNDLE_IDENTIFIER", "io.github.oieryangjz.quantummechanicslab"),
    ("PRODUCT_NAME", "QuantumMechanicsLab"),
    ("SUPPORTED_PLATFORMS", "\"iphoneos iphonesimulator\""),
    ("SUPPORTS_MACCATALYST", "NO"),
    ("SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD", "NO"),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ("SWIFT_VERSION", "6.0"),
    ("TARGETED_DEVICE_FAMILY", "2")
])


let testsTargetSettings = buildSettings([
    ("CODE_SIGN_STYLE", "Automatic"),
    ("PRODUCT_BUNDLE_IDENTIFIER", "io.github.oieryangjz.quantummechanicslab.coretests"),
    ("PRODUCT_NAME", "\"$(TARGET_NAME)\""),
    ("SWIFT_VERSION", "6.0"),
    ("TARGETED_DEVICE_FAMILY", "2"),
    ("TEST_HOST", "\"$(BUILT_PRODUCTS_DIR)/QuantumMechanicsLab.app/QuantumMechanicsLab\""),
    ("BUNDLE_LOADER", "\"$(TEST_HOST)\""),
    ("SUPPORTED_PLATFORMS", "\"iphoneos iphonesimulator\"")
])

let coreFileReferences = coreSources.map {
    "\t\t\($0.id) /* \($0.name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \($0.path); sourceTree = \"<group>\"; };"
}.joined(separator: "\n")

let testsFileReferences = testsSources.map { "\t\t\($0.id) /* \($0.name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \($0.path); sourceTree = \"<group>\"; };" }.joined(separator: "\n")

let appFileReferences = appSources.map {
    "\t\t\($0.id) /* \($0.name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \($0.path); sourceTree = \"<group>\"; };"
}.joined(separator: "\n")

let coreBuildFiles = coreSources.map {
    "\t\t\($0.buildID) /* \($0.name) in Sources */ = {isa = PBXBuildFile; fileRef = \($0.id) /* \($0.name) */; };"
}.joined(separator: "\n")

let testsBuildFiles = testsSources.map { "\t\t\($0.buildID) /* \($0.name) in Sources */ = {isa = PBXBuildFile; fileRef = \($0.id) /* \($0.name) */; };" }.joined(separator: "\n")

let appBuildFiles = appSources.map {
    "\t\t\($0.buildID) /* \($0.name) in Sources */ = {isa = PBXBuildFile; fileRef = \($0.id) /* \($0.name) */; };"
}.joined(separator: "\n")

let pbxproj = """
// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 77;
\tobjects = {

/* Begin PBXBuildFile section */
\(coreBuildFiles)
\(appBuildFiles)
\(testsBuildFiles)
\t\t\(coreFrameworkTestsBuildID) /* QuantumMechanicsLabCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = \(coreProductID) /* QuantumMechanicsLabCore.framework */; };
\t\t\(accelerateBuildID) /* Accelerate.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = \(accelerateFrameworkID) /* Accelerate.framework */; };
\t\t\(coreFrameworkBuildID) /* QuantumMechanicsLabCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = \(coreProductID) /* QuantumMechanicsLabCore.framework */; };
\t\t\(coreFrameworkEmbedID) /* QuantumMechanicsLabCore.framework in Embed Frameworks */ = {isa = PBXBuildFile; fileRef = \(coreProductID) /* QuantumMechanicsLabCore.framework */; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t\(dependencyProxyID) /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = \(projectID) /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = \(coreTargetID);
\t\t\tremoteInfo = QuantumMechanicsLabCore;
\t\t};
\t\t\(testsDependencyProxyID) /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = \(projectID) /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = \(appTargetID);
\t\t\tremoteInfo = QuantumMechanicsLab;
\t\t};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
\t\t\(appEmbedFrameworksPhaseID) /* Embed Frameworks */ = {
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 10;
\t\t\tfiles = (
\t\t\t\t\(coreFrameworkEmbedID) /* QuantumMechanicsLabCore.framework in Embed Frameworks */,
\t\t\t);
\t\t\tname = "Embed Frameworks";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
\(coreFileReferences)
\(appFileReferences)
\(testsFileReferences)
\t\t\(testsProductID) /* QuantumMechanicsLabCoreTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = QuantumMechanicsLabCoreTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
\t\t\(coreProductID) /* QuantumMechanicsLabCore.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = QuantumMechanicsLabCore.framework; sourceTree = BUILT_PRODUCTS_DIR; };
\t\t\(appProductID) /* QuantumMechanicsLab.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QuantumMechanicsLab.app; sourceTree = BUILT_PRODUCTS_DIR; };
\t\t\(accelerateFrameworkID) /* Accelerate.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = Accelerate.framework; path = System/Library/Frameworks/Accelerate.framework; sourceTree = SDKROOT; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t\(coreFrameworksPhaseID) /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t\(accelerateBuildID) /* Accelerate.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\t\(appFrameworksPhaseID) /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t\(coreFrameworkBuildID) /* QuantumMechanicsLabCore.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\t\(testsFrameworksPhaseID) /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t\(coreFrameworkTestsBuildID) /* QuantumMechanicsLabCore.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t\(mainGroupID) = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t\(coreGroupID) /* QuantumMechanicsLabCore */,
\t\t\t\t\(appGroupID) /* QuantumMechanicsLabApp */,
\t\t\t\t\(testsGroupID) /* QuantumMechanicsLabCoreTests */,
\t\t\t\t\(frameworksGroupID) /* Frameworks */,
\t\t\t\t\(productsGroupID) /* Products */,
\t\t\t);
\t\t\tsourceTree = \"<group>\";
\t\t};
\t\t\(coreGroupID) /* QuantumMechanicsLabCore */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\(quotedList(coreSources.map { "\($0.id) /* \($0.name) */" }))
\t\t\t);
\t\t\tname = QuantumMechanicsLabCore;
\t\t\tsourceTree = \"<group>\";
\t\t};
\t\t\(testsGroupID) /* QuantumMechanicsLabCoreTests */ = {
			isa = PBXGroup;
			children = (
\(quotedList(testsSources.map { "\($0.id) /* \($0.name) */" }))
			);
			name = QuantumMechanicsLabCoreTests;
			sourceTree = "<group>";
		};
		\(appGroupID) /* QuantumMechanicsLabApp */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\(quotedList(appSources.map { "\($0.id) /* \($0.name) */" }))
\t\t\t);
\t\t\tname = QuantumMechanicsLabApp;
\t\t\tsourceTree = \"<group>\";
\t\t};
\t\t\(frameworksGroupID) /* Frameworks */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t\(accelerateFrameworkID) /* Accelerate.framework */,
\t\t\t);
\t\t\tname = Frameworks;
\t\t\tsourceTree = \"<group>\";
\t\t};
\t\t\(productsGroupID) /* Products */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t\(coreProductID) /* QuantumMechanicsLabCore.framework */,
\t\t\t\t\(appProductID) /* QuantumMechanicsLab.app */,
\t\t\t\t\(testsProductID) /* QuantumMechanicsLabCoreTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t\(coreTargetID) /* QuantumMechanicsLabCore */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = \(coreConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLabCore" */;
\t\t\tbuildPhases = (
\t\t\t\t\(coreSourcesPhaseID) /* Sources */,
\t\t\t\t\(coreFrameworksPhaseID) /* Frameworks */,
\t\t\t\t\(coreResourcesPhaseID) /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = QuantumMechanicsLabCore;
\t\t\tproductName = QuantumMechanicsLabCore;
\t\t\tproductReference = \(coreProductID) /* QuantumMechanicsLabCore.framework */;
\t\t\tproductType = "com.apple.product-type.framework";
\t\t};
\t\t\(testsTargetID) /* QuantumMechanicsLabCoreTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = \(testsConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLabCoreTests" */;
			buildPhases = (
				\(testsSourcesPhaseID) /* Sources */,
				\(testsFrameworksPhaseID) /* Frameworks */,
				\(testsResourcesPhaseID) /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				\(testsDependencyID) /* PBXTargetDependency */,
			);
			name = QuantumMechanicsLabCoreTests;
			productName = QuantumMechanicsLabCoreTests;
			productReference = \(testsProductID) /* QuantumMechanicsLabCoreTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		\(appTargetID) /* QuantumMechanicsLab */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = \(appConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLab" */;
\t\t\tbuildPhases = (
\t\t\t\t\(appSourcesPhaseID) /* Sources */,
\t\t\t\t\(appFrameworksPhaseID) /* Frameworks */,
\t\t\t\t\(appResourcesPhaseID) /* Resources */,
\t\t\t\t\(appEmbedFrameworksPhaseID) /* Embed Frameworks */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t\(dependencyID) /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = QuantumMechanicsLab;
\t\t\tproductName = QuantumMechanicsLab;
\t\t\tproductReference = \(appProductID) /* QuantumMechanicsLab.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t\(projectID) /* Project object */ = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 2640;
\t\t\t\tLastUpgradeCheck = 2640;
\t\t\t\tTargetAttributes = {
\t\t\t\t\t\(coreTargetID) = {
\t\t\t\t\t\tCreatedOnToolsVersion = 26.4.1;
\t\t\t\t\t};
\t\t\t\t\t\(appTargetID) = {
\t\t\t\t\t\tCreatedOnToolsVersion = 26.4.1;
\t\t\t\t\t};
\t\t\t\t};
\t\t\t};
\t\t\tbuildConfigurationList = \(projectConfigListID) /* Build configuration list for PBXProject "QuantumMechanicsLab" */;
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = \(mainGroupID);
\t\t\tminimizedProjectReferenceProxies = 1;
\t\t\tpreferredProjectObjectVersion = 77;
\t\t\tproductRefGroup = \(productsGroupID) /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t\(coreTargetID) /* QuantumMechanicsLabCore */,
\t\t\t\t\(appTargetID) /* QuantumMechanicsLab */,
\t\t\t\t\(testsTargetID) /* QuantumMechanicsLabCoreTests */,
\t\t\t);
\t\t};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t\(coreResourcesPhaseID) /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
\t\t\(appResourcesPhaseID) /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
\t\t\(testsResourcesPhaseID) /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t\(coreSourcesPhaseID) /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\(quotedList(coreSources.map { "\($0.buildID) /* \($0.name) in Sources */" }))
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\t\(testsSourcesPhaseID) /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
\(quotedList(testsSources.map { "\($0.buildID) /* \($0.name) in Sources */" }))
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		\(appSourcesPhaseID) /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\(quotedList(appSources.map { "\($0.buildID) /* \($0.name) in Sources */" }))
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t\(dependencyID) /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = \(coreTargetID) /* QuantumMechanicsLabCore */;
\t\t\ttargetProxy = \(dependencyProxyID) /* PBXContainerItemProxy */;
\t\t};
\(testsDependencyID) /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = \(appTargetID) /* QuantumMechanicsLab */;
			targetProxy = \(testsDependencyProxyID) /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
\t\t\(projectDebugConfigID) /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {
\(projectDebugSettings)
\t\t}; name = Debug; };
\t\t\(projectReleaseConfigID) /* Release */ = {isa = XCBuildConfiguration; buildSettings = {
\(projectReleaseSettings)
\t\t}; name = Release; };
\t\t\(coreDebugConfigID) /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {
\(coreTargetSettings)
\t\t}; name = Debug; };
\t\t\(coreReleaseConfigID) /* Release */ = {isa = XCBuildConfiguration; buildSettings = {
\(coreTargetSettings)
\t\t}; name = Release; };
\t\t\(appDebugConfigID) /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {
\(appTargetSettings)
\t\t}; name = Debug; };
\t\t\(appReleaseConfigID) /* Release */ = {isa = XCBuildConfiguration; buildSettings = {
\(appTargetSettings)
\t\t}; name = Release; };
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t\(projectConfigListID) /* Build configuration list for PBXProject "QuantumMechanicsLab" */ = {isa = XCConfigurationList; buildConfigurations = (\(projectDebugConfigID) /* Debug */, \(projectReleaseConfigID) /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
\t\t\(coreConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLabCore" */ = {isa = XCConfigurationList; buildConfigurations = (\(coreDebugConfigID) /* Debug */, \(coreReleaseConfigID) /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
\t\t\(appConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLab" */ = {isa = XCConfigurationList; buildConfigurations = (\(appDebugConfigID) /* Debug */, \(appReleaseConfigID) /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
\t\t\(testsConfigListID) /* Build configuration list for PBXNativeTarget "QuantumMechanicsLabCoreTests" */ = {isa = XCConfigurationList; buildConfigurations = (\(testsDebugConfigID) /* Debug */, \(testsReleaseConfigID) /* Release */, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
/* End XCConfigurationList section */
\t};
\trootObject = \(projectID) /* Project object */;
}
"""

let scheme = """
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion="2640"
   version="1.7">
   <BuildAction
      parallelizeBuildables="YES"
      buildImplicitDependencies="YES"
      buildArchitectures="Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting="YES"
            buildForRunning="YES"
            buildForProfiling="YES"
            buildForArchiving="YES"
            buildForAnalyzing="YES">
            <BuildableReference
               BuildableIdentifier="primary"
               BlueprintIdentifier="\(appTargetID)"
               BuildableName="QuantumMechanicsLab.app"
               BlueprintName="QuantumMechanicsLab"
               ReferencedContainer="container:QuantumMechanicsLab.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration="Debug"
      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference
            skipped="NO">
            <BuildableReference
               BuildableIdentifier="primary"
               BlueprintIdentifier="\(testsTargetID)"
               BuildableName="QuantumMechanicsLabCoreTests.xctest"
               BlueprintName="QuantumMechanicsLabCoreTests"
               ReferencedContainer="container:QuantumMechanicsLab.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration="Debug"
      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle="0"
      useCustomWorkingDirectory="NO"
      ignoresPersistentStateOnLaunch="NO"
      debugDocumentVersioning="YES"
      debugServiceExtension="internal"
      allowLocationSimulation="YES">
      <BuildableProductRunnable
         runnableDebuggingMode="0">
         <BuildableReference
            BuildableIdentifier="primary"
            BlueprintIdentifier="\(appTargetID)"
            BuildableName="QuantumMechanicsLab.app"
            BlueprintName="QuantumMechanicsLab"
            ReferencedContainer="container:QuantumMechanicsLab.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration="Release"
      shouldUseLaunchSchemeArgsEnv="YES"
      savedToolIdentifier=""
      useCustomWorkingDirectory="NO"
      debugDocumentVersioning="YES">
      <BuildableProductRunnable
         runnableDebuggingMode="0">
         <BuildableReference
            BuildableIdentifier="primary"
            BlueprintIdentifier="\(appTargetID)"
            BuildableName="QuantumMechanicsLab.app"
            BlueprintName="QuantumMechanicsLab"
            ReferencedContainer="container:QuantumMechanicsLab.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration="Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration="Release"
      revealArchiveInOrganizer="YES">
   </ArchiveAction>
</Scheme>
"""

try FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: schemeDirectory, withIntermediateDirectories: true)
try pbxproj.write(to: projectFile, atomically: true, encoding: .utf8)
try scheme.write(to: schemeFile, atomically: true, encoding: .utf8)

print("Generated \(projectFile.path)")
print("Generated \(schemeFile.path)")
