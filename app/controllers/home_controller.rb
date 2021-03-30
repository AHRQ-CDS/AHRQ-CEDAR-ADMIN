# frozen_string_literal: true

# Primary application controller, providing a statistical overview of CEDAR
class HomeController < ApplicationController
  def index
    @artifact_count = Artifact.count
    @artifact_count_missing_description = Artifact.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = Artifact.where('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').count

    @artifacts_per_repository = Artifact.joins(:repository).group('repository').count
    @artifacts_by_status = Artifact.group(:artifact_status).count
    @top_10_artifacts_by_type = Artifact.group(:artifact_type).count.sort_by { |_, v| -v }[0, 10]

    artifacts_with_keywords = Artifact.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]')
    artifacts_per_keyword = artifacts_with_keywords.each_with_object(Hash.new(0)) do |artifact, hash|
      (artifact.keywords + artifact.mesh_keywords).each { |keyword| hash[keyword] += 1 }
    end
    @top_artifacts_per_keyword = artifacts_per_keyword.sort_by { |_, v| -v }[0, 10]
    # TODO: Refactor tag cloud to use REST, consider others above as well using built in chart-kick approach
    @keyword_counts = artifacts_per_keyword.map { |k, v| { text: k, size: v * 5 } }
  end

  def repository
    @repository = Repository.find(params[:id])
    artifacts = @repository.artifacts
    @artifact_count = artifacts.count
    @artifact_count_missing_description = artifacts.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = artifacts.where('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').count

    @artifacts_by_status = artifacts.group(:artifact_status).count
    @artifacts_by_type = artifacts.group(:artifact_type).count

    artifacts_with_keywords = artifacts.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]')
    artifacts_per_keyword = artifacts_with_keywords.each_with_object(Hash.new(0)) do |artifact, hash|
      # TODO: Add an "all_keywords" method and use it everywhere appropriate
      (artifact.keywords + artifact.mesh_keywords).each { |keyword| hash[keyword] += 1 }
    end
    @top_artifacts_per_keyword = artifacts_per_keyword.sort_by { |_, v| -v }[0, 10]
  end

  def artifact
    @artifact = Artifact.find(params[:id])
  end

  def keyword
    @keyword = params[:keyword]
    @artifacts = Artifact.where('keywords @> ? OR mesh_keywords @> ?', "[\"#{@keyword}\"]", "[\"#{@keyword}\"]")
    @artifacts_per_repository = @artifacts.joins(:repository).group('repository').count
    related_keywords = @artifacts.each_with_object([]) { |artifact, array| array.concat((artifact.keywords + artifact.mesh_keywords).uniq) } - [@keyword]
    @top_artifacts_per_keyword = related_keywords.tally.sort_by { |_, v| -v }[0, 10]
  end
end
