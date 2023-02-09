# frozen_string_literal: true

# Represents a user of the system
class User < ApplicationRecord
  # Others available modules are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  # :registerable, :recoverable, :rememberable, :validatable
  devise :ldap_authenticatable, :trackable
end
