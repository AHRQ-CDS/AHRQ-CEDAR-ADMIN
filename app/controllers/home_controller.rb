# frozen_string_literal: true

# Primary application controller, providing a statistical overview of CEDAR
class HomeController < ApplicationController
  # NOTE: If we want to show search count by publisher:
  # When no artifact-publisher is selected, the API queries against all artifact-publishers.
  # So, artifact-publisher is absent from the query params, even though the user of the API is querying
  # against all publishers. Thus, we must make sure any code calculating counts by publisher takes into account
  # that non-publisher-specifying searches are a search for all publishers
  def index
    @artifact_count = Artifact.count
    @artifact_count_missing_description = Artifact.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = Artifact.where('keywords <@ ?', '[]').count

    @artifacts_per_repository = Artifact.joins(:repository).group('repository').count
    @artifacts_by_status = Artifact.group(:artifact_status).count
    @top_artifacts_by_type = Artifact.group(:artifact_type).count.sort_by { |_, v| -v }[0, 10]

    @artifact_clicks = Artifact.joins(:search_stats)
                               .preload(:search_stats)
                               .where.not('search_stats.click_count': nil)
                               .order(click_count: :desc)
                               .limit(10)
    @artifact_clicks_per_repository = Artifact.joins(:search_stats, :repository).group(:repository).sum(:click_count)

    @returned_artifacts = Artifact.joins(:search_stats)
                                  .preload(:search_stats)
                                  .where.not('search_stats.returned_count': nil)
                                  .order(returned_count: :desc)
                                  .limit(10)
    @artifact_returns_per_repository = Artifact.joins(:search_stats, :repository).group(:repository).sum(:returned_count)

    # Set up import run data for display; first find the last (up to) 5 distinct calendar days when imports happened
    # then find all the import runs that happened over those days and group them by day
    start_dates = ImportRun.select('DISTINCT DATE(start_time) AS start_date').order(:start_date).reverse_order.limit(5).map(&:start_date)
    @import_runs = ImportRun.where('DATE(start_time) >= ?', start_dates.last).order(:start_time).reverse_order.group_by { |ir| ir.start_time.to_date }
    # take a similar approach for flagged runs, but don't limit that data to the last five days
    @flagged_runs = ImportRun.where(status: 'flagged').order(:start_time).reverse_order.group_by { |ir| ir.start_time.to_date }

    keywords = Artifact.where.not('keywords <@ ?', '[]').flat_map(&:keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]

    search_last_10_days = SearchLog.last_ten_days
    @search_per_day = SearchLog.last_ten_days.order('DATE(start_time) DESC').group('DATE(start_time)').count

    @search_per_parameter_name = {}
    @search_per_parameter_value = {}
    search_last_10_days.each do |search_log|
      search_log.search_params.each_pair do |param, value|
        next unless %w[_content classification classification:text title title:contains].include? param

        @search_per_parameter_name[param] ||= 0
        @search_per_parameter_name[param] += 1
        value = value.join(',') if value.respond_to? :join
        @search_per_parameter_value[value] ||= 0
        @search_per_parameter_value[value] += 1
      end
    end

    @search_logs = SearchLog.last_searches(10)
    @subnavigation = ['Artifacts', 'Imports', 'Tags', 'Searches', 'Back to Top']
  end

  def repository
    @repository = Repository.joins(:stats).find(params[:id])
    artifacts = @repository.artifacts
    @artifact_count = artifacts.count
    @artifact_count_missing_description = artifacts.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = artifacts.where('keywords <@ ?', '[]').count

    @artifacts_by_status = artifacts.group(:artifact_status).count
    @artifacts_by_type = artifacts.group(:artifact_type).count

    keywords = artifacts.where.not('keywords <@ ?', '[]').flat_map(&:keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]

    @artifact_clicks = Artifact.joins(:search_stats)
                               .preload(:search_stats)
                               .where(repository_id: @repository.id)
                               .where.not('search_stats.click_count': nil)
                               .order(click_count: :desc)
                               .limit(10)

    @returned_artifacts = Artifact.joins(:search_stats)
                                  .preload(:search_stats)
                                  .where(repository_id: @repository.id)
                                  .where.not('search_stats.returned_count': nil)
                                  .order(returned_count: :desc)
                                  .limit(10)
  end

  def import_run
    @import_run = ImportRun.find(params[:id])
    @versions = @import_run.versions.includes(:item)
  end

  def reject_run
    import_run = ImportRun.find(params[:id])
    import_run.update!(status: :suppressed)
    import_run.repository.update!(enabled: true)
    redirect_to :import_run
  end

  def accept_run
    # Rollback to prior version of each artifact to undo the suppression of the flagged changes
    PaperTrail.request(enabled: false)
    ImportRun.transaction do
      import_run = ImportRun.find(params[:id])
      import_run.versions.map(&:item).uniq.each do |artifact|
        artifact.paper_trail.previous_version&.save!
      end
      import_run.update!(status: :reviewed)
      import_run.repository.update!(enabled: true)
    end
    redirect_to :import_run
  end

  def artifact
    @artifact = Artifact.find(params[:id])
  end

  def version
    @version = PaperTrail::Version.find(params[:id])
  end

  def keyword
    @keyword = params[:keyword]
    @artifacts = Artifact.where('keywords @> ?', JSON.generate([@keyword]))
    @artifacts_per_repository = @artifacts.joins(:repository).group('repository').count
    related_keywords = @artifacts.flat_map(&:keywords) - [@keyword] # Don't include the keyword itself
    @top_artifacts_per_keyword = related_keywords.tally.sort_by { |_, v| -v }[0, 10]
  end

  # We use a RESTful call from the JavaScript tag cloud code to get the appropriate data
  def keyword_counts
    keyword_counts = Artifact.where.not('keywords <@ ?', '[]').flat_map(&:keywords).tally
    max_count = keyword_counts.values.max
    # Scale size from 1 to 100 based on the max_count
    scale_factor = 120.0 / max_count
    render json: keyword_counts.sort_by { |_, v| -v }.map { |k, v| { text: k, size: (v * scale_factor).ceil } }[0, 250]
  end

  def repository_report
    @repositories = Repository.order(:name)
  end

  def repository_missing
    @repository = Repository.find(params[:id])
    @missing_type = params[:missing]
    artifacts = @repository.artifacts

    case @missing_type
    when 'title'
      @missing_artifacts = artifacts.where('title IS NULL OR LENGTH(title) = 0').order(:id)
    when 'description'
      @missing_artifacts = artifacts.where('description IS NULL OR LENGTH(description) = 0').order(:id)
    when 'keyword'
      @missing_artifacts = artifacts.where('keywords IS NULL OR JSONB_ARRAY_LENGTH(keywords) = 0').order(:id)
    when 'concept'
      @missing_artifacts = artifacts.where(id: artifacts.left_joins(:artifacts_concepts).group(:id).having('COUNT(artifacts_concepts.concept_id) = 0'))
                                    .where('length(keyword_text) > 0')
                                    .order(:id)
    end
  end
end
