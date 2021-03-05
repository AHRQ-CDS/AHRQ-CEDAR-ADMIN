# frozen_string_literal: true

# Primary application controller, providing a statistical overview of CEDAR
class HomeController < ApplicationController
  def index
    @artifact_count = Artifact.count
    @artifact_count_missing_description = Artifact.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = Artifact.where('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').count

    @artifacts_per_repository = Artifact.joins(:repository).group('repositories.name').count
    @artifacts_by_status = Artifact.group(:artifact_status).count

    artifacts_with_keywords = Artifact.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]')
    artifacts_per_keyword = artifacts_with_keywords.each_with_object(Hash.new(0)) do |artifact, hash|
      (artifact.keywords + artifact.mesh_keywords).each { |keyword| hash[keyword] += 1 }
    end
    @top_artifacts_per_keyword = artifacts_per_keyword.sort_by { |_, v| -v }[0, 10]
  end
end
