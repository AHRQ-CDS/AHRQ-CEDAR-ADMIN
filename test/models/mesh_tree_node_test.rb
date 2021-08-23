# frozen_string_literal: true

require 'test_helper'

class MeshTreeNodeTest < ActiveSupport::TestCase
  test 'creating a Mesh Tree Node with no parent (root node) and no children' do
    mesh_tree_node = FactoryBot.create(:mesh_tree_node)

    assert_nil(mesh_tree_node.parent)
    assert_equal([], mesh_tree_node.children)
  end

  test 'creating a Mesh Tree Node with a parent' do
    mesh_parent_node = FactoryBot.create(:mesh_tree_node)
    mesh_child_node = FactoryBot.create(:mesh_tree_node, parent: mesh_parent_node)

    assert_equal(mesh_parent_node, mesh_child_node.parent)
    assert mesh_parent_node.children.include? mesh_child_node
    assert_equal(1, mesh_parent_node.children.count)
  end

  test 'creating a Mesh Tree Node with multiple children' do
    mesh_parent_node = FactoryBot.create(:mesh_tree_node)
    mesh_child_node_one = FactoryBot.create(:mesh_tree_node, parent: mesh_parent_node)
    mesh_child_node_two = FactoryBot.create(:mesh_tree_node, parent: mesh_parent_node)

    assert_equal(mesh_child_node_one.parent, mesh_parent_node)
    assert_equal(mesh_child_node_two.parent, mesh_parent_node)

    assert mesh_parent_node.children.include? mesh_child_node_one
    assert mesh_parent_node.children.include? mesh_child_node_two
    assert_equal(2, mesh_parent_node.children.count)
  end

  # NOTE: Many Mesh concepts are part of multiple trees. One such example is the Mesh concept "Printing, Three-Dimensional".
  # This concept is a child of three different tree_numbers, namely J01.897, L01.224.108.150, L01.296.110.150
  # Thus, the human-readable name associated with a concept may be part of several different Mesh trees
  test 'creating a Mesh Node that is part of multiple trees' do
    mesh_first_parent_node = FactoryBot.create(:mesh_tree_node)
    mesh_second_parent_node = FactoryBot.create(:mesh_tree_node)

    FactoryBot.create(:mesh_tree_node, parent: mesh_first_parent_node, name: 'Eukaryota')
    FactoryBot.create(:mesh_tree_node, parent: mesh_second_parent_node, name: 'Eukaryota')

    assert mesh_first_parent_node.children.map(&:name).include? 'Eukaryota'
    assert mesh_second_parent_node.children.map(&:name).include? 'Eukaryota'
  end
end
