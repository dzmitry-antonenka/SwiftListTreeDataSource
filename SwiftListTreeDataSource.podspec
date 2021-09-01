Pod::Spec.new do |s|
  s.name = 'SwiftListTreeDataSource'
  s.version = '1.0.0'
  s.license = 'MIT'
  s.summary = 'Swift list tree data souce package to display hierachical data structures lists-like way'
  s.homepage = 'https://github.com/dzmitry-antonenka/SwiftListTreeDataSource'
  s.author = 'dzmitry.antonenka@gmail.com'
  s.source = { :git => 'https://github.com/dzmitry-antonenka/SwiftListTreeDataSource.git', :branch => "main", :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.swift_versions = ['5.4']

  s.source_files = 'Sources/SwiftListTreeDataSource/*.swift'
end
