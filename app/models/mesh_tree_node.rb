# frozen_string_literal: true

# Represents a MeshTreeNode in the MeshTree hierarchy
class MeshTreeNode < ApplicationRecord
  has_many :children, class_name: 'MeshTreeNode', foreign_key: 'parent_id', inverse_of: :parent, dependent: :nullify
  belongs_to :parent, class_name: 'MeshTreeNode', optional: true, inverse_of: :children

  validates :tree_number, presence: true

  scope :roots, -> { where(parent_id: nil) }
end
