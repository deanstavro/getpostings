class User < ApplicationRecord
  
  belongs_to :client_company, optional: true
  enum role: [:user, :scalerep, :admin]
  after_initialize :set_default_role, :if => :new_record?
  after_create :generate_key

  has_many :accounts
  has_many :leads
  has_many :find_companies
  has_many :find_contacts

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  validates :email, presence: true
  validates_uniqueness_of :email




 
  def set_default_role
    self.role ||= :user
  end

  def generate_key
    begin
      self.api_key = SecureRandom.hex
    end while self.class.exists?(api_key: api_key)
    self.save!
  end

  

end
