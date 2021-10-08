# frozen_string_literal: true

# Primary application controller, providing a statistical overview of CEDAR
class HomeController < ApplicationController
  def index
    @artifact_count = Artifact.count
    @artifact_count_missing_description = Artifact.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = Artifact.where('keywords <@ ?', '[]').count

    @artifacts_per_repository = Artifact.joins(:repository).group('repository').count
    @artifacts_by_status = Artifact.group(:artifact_status).count
    @top_artifacts_by_type = Artifact.group(:artifact_type).count.sort_by { |_, v| -v }[0, 10]

    # Set up import run data for display; first find the last (up to) 5 distinct calendar days when imports happened
    start_dates = ImportRun.select('DISTINCT DATE(start_time) AS start_date').order(:start_date).reverse_order.limit(5).map(&:start_date)
    # Find all the import runs that happened over those days and group them by day
    @import_runs = ImportRun.where('DATE(start_time) >= ?', start_dates.last).order(:start_time).reverse_order.group_by { |ir| ir.start_time.to_date }
    # Create summaries for each date
    @import_run_summaries = @import_runs.transform_values do |irs|
      ImportRun.new(total_count: irs.sum(&:total_count), new_count: irs.sum(&:new_count),
                    update_count: irs.sum(&:update_count), delete_count: irs.sum(&:delete_count))
    end

    keywords = Artifact.where.not('keywords <@ ?', '[]').flat_map(&:keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]

    search_last_10_days = SearchLog.last_ten_days
    @search_per_day = SearchLog.last_ten_days.order('DATE(start_time) DESC').group('DATE(start_time)').count

    search_parameter_last_10_days = SearchParameterLog.joins(:search_log).where(search_log_id: search_last_10_days.map(&:id))
    @search_per_parameter_name = search_parameter_last_10_days.group(:name).order(count_all: :desc).count
    @search_per_parameter_value = search_parameter_last_10_days.group(:value).order(count_all: :desc).limit(20).count

    @search_logs = SearchLog.last_searches(10)
    @subnavigation = ['Artifacts', 'Imports', 'Tags', 'Searches', 'Back to Top']
  end

  def repository
    @repository = Repository.find(params[:id])
    artifacts = @repository.artifacts
    @artifact_count = artifacts.count
    @artifact_count_missing_description = artifacts.where(description: nil, description_html: nil, description_markdown: nil).count
    @artifact_count_missing_keywords = artifacts.where('keywords <@ ?', '[]').count

    @artifacts_by_status = artifacts.group(:artifact_status).count
    @artifacts_by_type = artifacts.group(:artifact_type).count

    keywords = artifacts.where.not('keywords <@ ?', '[]').flat_map(&:keywords)
    @top_artifacts_per_keyword = keywords.tally.sort_by { |_, v| -v }[0, 10]

    query = <<-SQL.squish
      WITH concept_count as (
        SELECT a.id, COUNT(ac.concept_id) as count_all FROM artifacts a
        LEFT JOIN artifacts_concepts ac ON a.id = ac.artifact_id
        GROUP BY a.id
      )
      SELECT
        a.artifact_type,
        COUNT(*) AS total,
        SUM(
          CASE WHEN (
            (a.title IS NULL OR LENGTH(a.title) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_title,
        SUM(
          CASE WHEN (
            (a.description IS NULL OR LENGTH(a.description) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_desc,
        SUM(
          CASE WHEN (
            (a.keywords IS NULL OR JSONB_ARRAY_LENGTH(a.keywords) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_keyword,
        SUM(
          CASE WHEN (
            (ac.count_all IS NULL OR ac.count_all = 0)
          )
          THEN 1 ELSE 0 END) AS missing_concept
      FROM
        artifacts a
      INNER JOIN
        concept_count ac on a.id = ac.id
      WHERE
        a.repository_id = $1
      GROUP BY
        a.artifact_type
      ORDER BY
        COUNT(*) DESC;
    SQL
    binds = [
      ActiveRecord::Relation::QueryAttribute.new('repository_id', params[:id].to_i, ActiveRecord::Type::Integer.new)
    ]
    @missing_attribute = ActiveRecord::Base.connection.exec_query(query, 'sql_repository_missing_records', binds)
  end

  def import_run
    @import_run = ImportRun.find(params[:id])
    @versions = @import_run.versions.includes(:item)
  end

  def artifact
    @artifact = Artifact.find(params[:id])
  end

  def version
    @version = PaperTrail::Version.find(params[:id])
  end

  def keyword
    @keyword = params[:keyword]
    @artifacts = Artifact.where('keywords @> ?', "[\"#{@keyword}\"]")
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
    query = <<-SQL.squish
      WITH concept_count as (
        SELECT a.id, COUNT(ac.concept_id) as count_all FROM artifacts a
        LEFT JOIN artifacts_concepts ac ON a.id = ac.artifact_id
        GROUP BY a.id
      )
      SELECT
        r.name as repository,
        r.id as repository_id,
        COUNT(*) AS total,
        SUM(
          CASE WHEN (
            (a.title IS NULL OR LENGTH(a.title) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_title,
        SUM(
          CASE WHEN (
            (a.description IS NULL OR LENGTH(a.description) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_desc,
        SUM(
          CASE WHEN (
            (a.keywords IS NULL OR JSONB_ARRAY_LENGTH(a.keywords) = 0)
          )
          THEN 1 ELSE 0 END) AS missing_keyword,
        SUM(
          CASE WHEN (
            (ac.count_all IS NULL OR ac.count_all = 0)
          )
          THEN 1 ELSE 0 END) AS missing_concept
      FROM
        artifacts a
      INNER JOIN
        repositories r on a.repository_id = r.id
      INNER JOIN
        concept_count ac on a.id = ac.id
      GROUP BY
        r.name, r.id
      ORDER BY
        r.name
    SQL
    @missing_fields = ActiveRecord::Base.connection.exec_query(query)
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
