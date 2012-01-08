gem 'activerecord', '>= 2.3'

##
# signature tracking
# ==================
# 
# signature tracking adds a model that represents an electronic signature for a
# user.
# 
# &copy; 2009 Andrew Coleman
# Released under MIT license.
# http://www.opensource.org/licenses/mit-license.php
# 
# signature tracked models
# ========================
# 
# This is used to allow for users to track any number of models with a signature
# to denote that they have really looked at the document. Usage of the tracking
# is quite easy.
# 
# Examples:
# 
#   class ClinicalChart < ActiveRecord::Base
#     track_signatures
#   end
# 
# Also, you might need to tell if a model has been tracked:
# 
# signed?
#   Determines if any signature has been made at all.
# 
# is_signed_by_user?(user)
#   Checks if the given user has signed the model. Returns signature if found.
#   Also matches the user against it's associated physician and the physician
#   stored in the signature.
#
# is_signed_by_role_key?(role_key)
#   Checks to see if any user has signed this chart with a key from
#   Role.extended_base_roles. Matches signature physician id only if the
#   role_key is :physician.
# 

module Consolo
  module SignatureTracking
    module ClassMethods
      ##
      # Checks to see if this class has signature tracking enabled
      #
      def has_signature_tracking?
        false
      end
      
      ##
      # Tracks signatures for a model. Adds a nice untracked_items method to
      # the class for easy tracking later.
      #
      def track_signatures
        self.class_eval do
          has_many :signatures, :as => :owner, :dependent => :destroy
        end
        
        self.class_eval <<-RUBY
          def self.has_signature_tracking?
            true
          end
          
          def self.unsigned_items
            self.all :joins => "LEFT JOIN signatures ON signatures.owner_id = #{self.table_name}.id AND signatures.owner_type = '#{self.name}' AND signatures.physician_id IS NOT NULL", :conditions => 'signatures.physician_id IS NULL'
          end
          
          def track_signature!(user, physician = nil, effective_date = nil)
            effective_date ||= Time.zone.try(:today)
            effective_date ||= Date.today
            physician ||= user.physician if user.physician
            self.signatures.create(
              :user => user,
              :physician => physician,
              :effective_date => (physician.nil? ? nil : effective_date)
            )
          end
          
          def is_signed_by_user?(user)
            self.signatures.detect do |signature|
              signature.user_id == user.id and user.physician.try(:id) == signature.physician_id
            end
          end
          
          def is_signed_by_physician?(physician)
            self.signatures.detect do |signature|
              physician and physician == signature.physician
            end
          end
          
          def is_signed_by_discipline?(discipline)
            role_name = Role.extended_base_roles[discipline]
            physician_match = discipline == :physician
            self.signatures.detect do |signature|
              signature.user.role.try(:root_role).try(:name) == role_name and (physician_match or signature.physician_id.nil?)
            end
          end
        RUBY
        
        Signature.track_type(self.name)
        
        include Consolo::SignatureTracking::InstanceMethods
      end
    end
    
    module InstanceMethods
      ##
      # Checks to see if the model has any signatures assigned.
      #
      def has_signature?
        !self.signatures.empty?
      end
      
      ##
      # Does a slightly better check that determines if this model has any
      # signatures with a Physician.
      #
      def has_physician_signature?
        !self.signatures.detect { |s| !s.physician.nil? }.nil?
      end
      
      ##
      # Checks to see if a particular user has signed a model. Requires the
      # actual User associated.
      #
      def has_signature_by?(check_user = nil)
        if check_user and self.signatures.detect { |s| s.user_id == check_user.id and s.physician.nil? }
          true
        else
          false
        end
      end
    end
    
  end
end

ActiveRecord::Base.send :extend, Consolo::SignatureTracking::ClassMethods
