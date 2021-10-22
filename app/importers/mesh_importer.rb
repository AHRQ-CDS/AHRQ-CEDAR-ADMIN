# frozen_string_literal: true

# Functionality for populating the MeshTerm and MeshTreeNode tables
class MeshImporter
  # NOTE: The root nodes for the Mesh trees are not included in the XML file, so we include them here
  # Source: https://meshb.nlm.nih.gov/treeView
  MESH_ROOTS = {
    A: 'Anatomy',
    B: 'Organisms',
    C: 'Diseases',
    D: 'Chemicals and Drugs',
    E: 'Analytical, Diagnostic and Therapeutic Techniques, and Equipment',
    F: 'Psychiatry and Psychology',
    G: 'Phenomena and Processes',
    H: 'Disciplines and Occupations',
    I: 'Anthropology, Education, Sociology, and Social Phenomena',
    J: 'Technology, Industry, and Agriculture',
    K: 'Humanities',
    L: 'Information Science',
    M: 'Named Groups',
    N: 'Health Care',
    V: 'Publication Characteristics',
    Z: 'Geographicals'
  }.freeze

  # NOTE: xml_file is sourced from the following URL, downloaded, and placed in project root:
  # https://nlmpubs.nlm.nih.gov/projects/mesh/MESH_FILES/xmlmesh/
  def self.import_mesh(xml_file)
    doc = Nokogiri::XML(File.read(xml_file))
    import_mesh_tree_nodes(doc)
    import_mesh_tree_structure(doc)
  end

  def self.import_mesh_tree_nodes(doc)
    doc.search('.//DescriptorRecord').each do |record|
      name = record.xpath('.//DescriptorName').first.text.strip
      code = record.xpath('.//DescriptorUI').first.text.strip
      scope_note = record.xpath('.//ConceptList//Concept//ScopeNote')
      description = scope_note.nil? ? '' : scope_note.text.strip

      record.xpath('.//TreeNumberList//TreeNumber').each do |number|
        MeshTreeNode.find_or_create_by(
          code: code,
          tree_number: number.text,
          name: name,
          description: description
        )
      end
    end

    MESH_ROOTS.each do |tree_number, name|
      MeshTreeNode.find_or_create_by(
        tree_number: tree_number,
        name: name,
        description: name
      )
    end
  end

  def self.import_mesh_tree_structure(doc)
    doc.search('.//DescriptorRecord').each do |record|
      record.xpath('.//TreeNumberList//TreeNumber').each do |number|
        tree_number = number.text

        parent_number, = tree_number.rpartition('.')

        # NOTE: If the parent_number is blank, the parent is one of the MESH_ROOTS
        # Example: For Health Occupations [H02], when we partition on '.' we yield a blank
        # The parent should be set to "H" for 'Disciplines and Occupations' as per MESH_ROOTS dict
        parent_number = tree_number[0] if parent_number.blank?

        mesh_tree_node = MeshTreeNode.find_by(tree_number: tree_number)
        mesh_tree_parent = MeshTreeNode.find_by(tree_number: parent_number)

        mesh_tree_node.update!(parent: mesh_tree_parent)
      end
    end
  end

  def self.update_artifact_counts
    # Compute counts of artifacts that include each MeSH concept
    # "Direct" means that the artifact directly references a concept
    # "Indirect" means that the artifact directly references a child concept in the MeSH tree
    mesh_nodes = {}
    Artifact.includes(:concepts).all.each do |artifact|
      artifact.concepts.each do |concept|
        concept.codes.each do |code|
          next if %w[MSH MSHSPA].exclude?(code['system'])

          # Find each MeSH tree node (there can be more than one) with this unique code
          MeshTreeNode.where(code: code['code']).each do |mesh_node|
            mesh_nodes[mesh_node.id] ||= {
              code: mesh_node.code, # not used but useful for debugging
              direct: 0,
              indirect: 0,
              counted_sources: {}
            }
            artifact_source_code = "#{artifact.id}_#{mesh_node.code}"
            # Don't double count when the same MeSH code appears more than once, e.g. if there
            # are English and Spanish language versions of the same code
            unless mesh_nodes[mesh_node.id][:counted_sources].include? artifact_source_code
              mesh_nodes[mesh_node.id][:direct] += 1
              mesh_nodes[mesh_node.id][:counted_sources][artifact_source_code] = true
            end
            # Now visit each parent node walking up the tree and add to their indirect counts
            parent_node_id = mesh_node.parent_id
            while parent_node_id.present?
              parent_node = MeshTreeNode.find(parent_node_id)
              mesh_nodes[parent_node_id] ||= {
                code: parent_node.code, # not used but useful for debugging
                direct: 0,
                indirect: 0,
                counted_sources: {}
              }
              # Don't double count when the same MeSH code appears more than once or when a
              # MeSH code is present in multiple tree branches
              unless mesh_nodes[parent_node.id][:counted_sources].include? artifact_source_code
                mesh_nodes[parent_node.id][:indirect] += 1
                mesh_nodes[parent_node.id][:counted_sources][artifact_source_code] = true
              end
              parent_node_id = parent_node.parent_id
            end
          end
        end
      end
    end

    # Save counts to database
    mesh_nodes.each_pair do |mesh_node_id, count|
      MeshTreeNode.update(
        mesh_node_id,
        direct_artifact_count: count[:direct],
        indirect_artifact_count: count[:indirect]
      )
    end
    MeshTreeNode.where.not(id: mesh_nodes.keys).each do |mesh_node|
      mesh_node.update(direct_artifact_count: 0, indirect_artifact_count: 0)
    end
  end
end
