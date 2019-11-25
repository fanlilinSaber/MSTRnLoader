Pod::Spec.new do |spec|
  spec.name = "MSTRnLoader"
  spec.version = "1.0.3"
  spec.summary = "MMA react-native-update"
  spec.homepage = "http://192.168.0.15/marsdt/marsdt-ios/MSTRnLoader.git"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Fan Li Lin" => 'fanlilin@i-focusing.com' }
  spec.platform = :ios, "9.0"
  spec.requires_arc = true
  spec.source = { git: "http://192.168.0.15/marsdt/marsdt-ios/MSTRnLoader.git", tag: spec.version, submodules: true }
  spec.source_files = 'Sources/*.{h,m}', 'Sources/BSDIFF/*.{h,m,c}'
  spec.resources = "Sources/*.bundle"
  spec.libraries = "bz2"
  spec.dependency "React"
  spec.dependency "AFNetworking", '~> 3.0'
  spec.dependency "SSZipArchive", '2.2.2'
end
