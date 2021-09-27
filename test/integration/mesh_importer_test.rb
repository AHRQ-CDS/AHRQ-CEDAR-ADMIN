# frozen_string_literal: true

require 'test_helper'

class MeshImporterTest < ActiveSupport::TestCase
  test 'import concepts and tree structure from Mesh' do
    # Ensure that no concepts are loaded before the test runs
    assert_equal(0, MeshTreeNode.all.count)

    MeshImporter.import_mesh(file_fixture('desc2021.xml'))

    # There are 16 roots, which correspond to categories such as Anatomy, Organisms, Diseases, etc.
    assert_equal(16, MeshTreeNode.roots.count)

    # There are 20 total nodes, including the roots and 4 others
    assert_equal(20, MeshTreeNode.all.count)

    # All records in the fixture XML file have the Organism node as their root
    organisms_tree = MeshTreeNode.find_by(name: 'Organisms')
    assert_equal(2, organisms_tree.children.count)
    assert organisms_tree.children.map(&:name).include? 'Organism Forms'
    assert organisms_tree.children.map(&:name).include? 'Eukaryota'

    amoebozoa_node = MeshTreeNode.find_by(name: 'Amoebozoa')
    assert_equal(amoebozoa_node.parent.name, 'Eukaryota')
    assert_equal(1, amoebozoa_node.children.count)
    assert amoebozoa_node.children.map(&:name).include? 'Mycetozoa'

    # No records in the fixture XML file have the Anatomy node as root
    anatomy_tree = MeshTreeNode.find_by(name: 'Anatomy')
    assert_equal(0, anatomy_tree.children.count)

    # Import again and make sure the Mesh Terms weren't duplicated
    MeshImporter.import_mesh(file_fixture('desc2021.xml'))

    assert_equal(16, MeshTreeNode.roots.count)
    assert_equal(20, MeshTreeNode.all.count)
  end

  test 'count artifacts for MeSH concepts' do
    MeshImporter.import_mesh(file_fixture('desc2021.xml'))
    ConceptImporter.import_umls_mrconso(file_fixture('umls_mth.rrf'))
    artifact_list_mock = file_fixture('ehc_product_feed.xml').read
    stub_request(:get, /product-feed/).to_return(status: 200, headers: { 'Content-Type' => 'application/xml' }, body: artifact_list_mock)
    assert_equal(0, Repository.where(name: 'EHC').count)
    EhcImporter.run
    MeshImporter.update_artifact_counts

    # 2 artifacts have the keyword 'Mycetozoa'
    mycetozoa = MeshTreeNode.find_by(name: 'Mycetozoa')
    assert_equal(2, mycetozoa.direct_artifact_count)
    assert_equal(0, mycetozoa.indirect_artifact_count)

    # walk the tree and ensure parent nodes reflect indirect artifact counts
    parent = mycetozoa.parent
    while parent.present?
      assert_equal(2, parent.indirect_artifact_count)
      assert_equal(0, parent.direct_artifact_count)
      parent = parent.parent
    end
  end
end
