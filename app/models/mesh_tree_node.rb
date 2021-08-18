# frozen_string_literal: true

# Represents a MeshTreeNode in the MeshTree hierarchy
class MeshTreeNode < ApplicationRecord
  has_ancestry

  validates :tree_number, presence: true
end
