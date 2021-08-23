# frozen_string_literal: true

# Represents a MeshTreeNode in the MeshTree hierarchy
class MeshTreeNode < ApplicationRecord
  has_many :children, class_name: 'MeshTreeNode', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'MeshTreeNode', foreign_key: 'parent_id', optional: true

  validates :tree_number, presence: true

  scope :roots, -> { where(parent_id: nil) }
end
