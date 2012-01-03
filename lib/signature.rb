##
# This is the representation of a signature to track a model with.
#
class Signature < ActiveRecord::Base
  acts_as_restricted_subdomain
  
  belongs_to :owner, :polymorphic => true
  belongs_to :user
  belongs_to :physician
  validates_presence_of :owner_id, :owner_type, :user
  validates_presence_of :effective_date, :if => lambda { |r| !r.physician_id.nil? }
  cattr_accessor :tracked_types
  
  before_create :make_static_fields
  
  named_scope :chronological, :order => "signatures.effective_date DESC, signatures.created_at DESC"
  
  ##
  # Checks if a particular class has been included with this plugin.
  #
  def self.tracked_type?(dest)
    self.tracked_types ||= []
    self.tracked_types.include?(dest)
  end
  
  ##
  # Returns an array of classes ready for use of the tracked types.
  #
  def self.tracked_classes
    self.tracked_types ||= []
    self.tracked_types.collect do |tt|
      tt.constantize
    end.compact
  end
  
  ##
  # Assigns a type to be tracked. Saves a string of the given argument.
  #
  def self.track_type(dest)
    self.tracked_types ||= []
    self.tracked_types << dest unless self.tracked_type?(dest)
  end
  
  ##
  # Converts this Signature into a prettied HTML compatible string.
  #
  def to_html
    signed_date = self.effective_date.nil? ? self.created_at.try(:in_time_zone).to_date : self.effective_date
    signed_label = if self.physician_id?
      if self.physician.nurse_practitioner?
        "Nurse Practitioner"
      elsif self.physician.is_medical_director?
        "Medical Director"
      else
        'Physician'
      end
    else 
      'User'
    end
      
    "#{self.static_role} <strong>#{self.static_name}</strong> (#{signed_label}) signed on <strong>#{signed_date}</strong>. Recorded by #{self.static_user_name} on #{self.created_at.try(:in_time_zone).try(:to_date)}."
  end
  
  protected
  
  ##
  # Records the Name and Role of the User or Physician of this Signature
  # at creation time in case any of the fields change in the future.
  #
  def make_static_fields
    if self.physician
      self.static_role = if self.physician.nurse_practitioner? 
        "Nurse Practitioner"
      elsif self.physician.is_medical_director? 
        "Medical Director"
      else
        "Physician"
      end
      self.static_name = self.physician.name.to_s
      self.static_user_name = self.user.user_name.to_s
    else
      self.static_role = self.user.role.try(:root_role).try(:name)
      self.static_name = self.user.name.to_s
      self.static_user_name = self.user.user_name
    end
  end
end
