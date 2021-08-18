# frozen_string_literal: true

# Functionality for populating the MeshTerm and MeshTreeNode tables
class MeshImporter
  # NOTE: The root nodes for the Mesh trees are not included in the XML file, so we include them here
  # Source: https://meshb.nlm.nih.gov/treeView
  MESH_ROOTS = {
    'A': 'Anatomy',
    'B': 'Organisms',
    'C': 'Diseases',
    'D': 'Chemicals and Drugs',
    'E': 'Analytical, Diagnostic and Therapeutic Techniques, and Equipment',
    'F': 'Psychiatry and Psychology',
    'G': 'Phenomena and Processes',
    'H': 'Disciplines and Occupations',
    'I': 'Anthropology, Education, Sociology, and Social Phenomena',
    'J': 'Technology, Industry, and Agriculture',
    'K': 'Humanities',
    'L': 'Information Science',
    'M': 'Named Groups',
    'N': 'Health Care',
    'V': 'Publication Characteristics',
    'Z': 'Geographicals'
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
end
