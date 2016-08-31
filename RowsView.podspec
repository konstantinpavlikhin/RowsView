Pod::Spec.new do |spec|

  spec.name = 'RowsView'

  spec.version = '0.1.0'

  spec.authors = {'Konstantin Pavlikhin' => 'k.pavlikhin@gmail.com'}

  spec.social_media_url = 'https://twitter.com/kpavlikhin'

  spec.license = {:type => 'MIT', :file => 'LICENSE.md'}

  spec.homepage = 'https://github.com/konstantinpavlikhin/RowsView'

  spec.source = {:git => 'https://github.com/konstantinpavlikhin/RowsView', :tag => "v#{spec.version}"}

  spec.summary = 'A simple grid-like view that arranges its cells in rows.'

  spec.platform = :osx, "10.11"

  spec.osx.deployment_target = "10.9"

  spec.requires_arc = true

  spec.frameworks = 'Cocoa'

  spec.source_files = "Sources/*.swift"

end
