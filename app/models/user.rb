# frozen_string_literal: true

class User < ApplicationRecord
  # Others available modules are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  # :registerable, :recoverable, :rememberable, :validatable
  devise :ldap_authenticatable, :trackable
end
