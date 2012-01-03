gem 'activerecord', '~> 2.3'

require 'lib/signature'
require 'lib/active_record_glue'

ActiveRecord::Base.send :extend, Consolo::SignatureTracking::ClassMethods

