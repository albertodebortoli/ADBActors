Pod::Spec.new do |s|
  s.name     = 'ADBActors'
  s.version  = '1.0.0'
  s.platform = :ios, '5.0'
  s.summary  = 'Simple concept of Actor Model in Objective-C based on the idea of Valletta Ventures.'
  s.homepage = 'https://github.com/albertodebortoli/ADBActors'
  s.author   = { 'Alberto De Bortoli' => 'albertodebortoli.website@gmail.com' }
  s.source   = { :git => 'https://github.com/albertodebortoli/ADBActors.git', :tag => s.version.to_s }
  s.license      = { :type => 'New BSD License', :file => 'LICENSE' }
  s.source_files = 'Src/*.{h,m}'
  s.requires_arc = true
end
