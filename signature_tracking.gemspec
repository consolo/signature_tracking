Gem::Specification.new do |s|
  s.name = 'signature_tracking'
  s.version = '1.0.0'
  s.author = 'Andrew Coleman'
  s.email = 'developers@consoloservices.com'
  s.summary = 'Signature tracking'
  s.description = 'Custom signature tracking and Active Record glue'
  s.homepage = 'https://redmine.consoloservices.com'
  s.require_path = '.'
  s.files = [ 'signature_tracking.rb', 'signature.rb', 'active_record_glue.rb' ]
  s.add_development_dependency 'activerecord', '~> 2.3'
end
