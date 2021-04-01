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

    keywords = Artifact.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').flat_map(&:all_keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]
  end

  def repository
    @repository = Repository.find(params[:id])
    artifacts = @repository.artifacts
    @artifact_count = artifacts.count
    @artifact_count_missing_description = artifacts.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = artifacts.where('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').count

    @artifacts_by_status = artifacts.group(:artifact_status).count
    @artifacts_by_type = artifacts.group(:artifact_type).count

    keywords = artifacts.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').flat_map(&:all_keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]
  end

  def artifact
    @artifact = Artifact.find(params[:id])
  end

  def keyword
    @keyword = params[:keyword]
    @artifacts = Artifact.where('keywords @> ? OR mesh_keywords @> ?', "[\"#{@keyword}\"]", "[\"#{@keyword}\"]")
    @artifacts_per_repository = @artifacts.joins(:repository).group('repository').count
    related_keywords = @artifacts.flat_map(&:all_keywords) - [@keyword] # Don't include the keyword itself
    @top_artifacts_per_keyword = related_keywords.tally.sort_by { |_, v| -v }[0, 10]
  end

  # We use a RESTful call from the JavaScript tag cloud code to get the appropriate data
  def keyword_counts
    keyword_counts = Artifact.where.not('keywords <@ ? AND mesh_keywords <@ ?', '[]', '[]').flat_map(&:all_keywords).tally
    max_count = keyword_counts.values.max
    # Scale size from 1 to 100 based on the max_count
    scale_factor = 120.0 / max_count
    render json: keyword_counts.sort_by { |_, v| -v }.map { |k, v| { text: k, size: (v * scale_factor).ceil } }[0, 250]
  end
end
