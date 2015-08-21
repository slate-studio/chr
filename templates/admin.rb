class Admin
  include Mongoid::Document
  include Mongoid::Timestamps
  include Ants::Id

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :authentication_keys => [ :email ]

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time
end