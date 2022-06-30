# frozen_string_literal: true

# Functionality for importing data from the USPSTF repository
class UspstfImporter < CedarImporter
  repository_name 'United States Preventive Services Taskforce'
  repository_alias 'USPSTF'
  repository_home_page Rails.configuration.uspstf_home_page

  include PageScraper

  def self.download_and_update!
    uri = URI(Rails.configuration.uspstf_base_url)
    json = Net::HTTP.get(uri)
    importer = UspstfImporter.new(json)
    importer.update_db!
  end

  def initialize(uspstf_json)
    super()
    @json_data = JSON.parse(uspstf_json)
  end

  def update_db!
    # Some metadata is only present at the general recommendation level, capture it here
    general_rec_info = {}
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      slug = recommendation['uspstfAlias']
      url = "#{Rails.configuration.uspstf_home_page}recommendation/#{slug}"
      keywords = recommendation['keywords']&.split('|') || []
      recommendation['categories'].each do |cat|
        keywords << @json_data['categories'][cat.to_s]['name']
      end
      general_rec_info[id.to_s] = {
        url: url,
        # Keywords are only specified at the general recommendation level so we save them here for
        # use in the associated specific recommendations and the tools that are linked from the
        # specific recommendations.
        keywords: keywords,
        slug: slug,
        sorts: [] # populated with sort order of associated specific recommendations
      }
    end

    # Extract specific recommendations
    tool_general_rec_info = {} # captures the general recommendation for each tool
    grade_statements = @json_data['grades']
    @json_data['specificRecommendations'].each do |recommendation|
      remote_id = recommendation['id'].to_s
      general_rec_id = recommendation['general'].to_s
      general_rec = general_rec_info[general_rec_id]
      if general_rec.nil?
        Rails.logger.warn "Skipping USPSTF specific recommendation (#{recommendation['title']}) " \
                          "with a missing parent general recommendation (id=#{general_rec_id})"
        next
      end

      # The cedar id of a specific recommendation is made relative to the associated
      # general recommendation. This ensures a unique id if the USPSTF changes the
      # id (remote_id here).
      cedar_id = "USPSTF-#{Digest::MD5.hexdigest(general_rec[:slug] + remote_id)}"
      recommendation['tool'].each do |tool_id|
        tool_general_rec_info[tool_id.to_s] = general_rec
      end
      strength_score = recommendation['grade']
      strength_sort = compute_strength_of_evidence_score(strength_score)
      general_rec[:sorts] << strength_sort

      # TODO: publish date and url are not explicit fields in the JSON
      update_or_create_artifact!(
        cedar_id,
        remote_identifier: remote_id,
        title: recommendation['title'],
        description_html: recommendation['text'],
        url: general_rec[:url],
        keywords: general_rec[:keywords],
        artifact_type: 'Specific Recommendation',
        artifact_status: 'active',
        strength_of_recommendation_statement: grade_statements[strength_score][1],
        strength_of_recommendation_score: strength_score,
        strength_of_recommendation_sort: strength_sort,
        quality_of_evidence_statement: grade_statements[strength_score][0],
        quality_of_evidence_score: strength_score,
        quality_of_evidence_sort: strength_sort
      )
    end

    # Extract general recommendations
    @json_data['generalRecommendations'].each_pair do |id, recommendation|
      warnings = []
      general_rec = general_rec_info[id.to_s]
      cedar_id = "USPSTF-#{Digest::MD5.hexdigest(general_rec[:slug])}"
      strength_sort = general_rec[:sorts].max || 0

      date = parse_by_core_format(recommendation['topicYear'].to_s) unless recommendation['topicYear'].nil?
      if date.nil?
        warnings << "Encountered #{general_rec[:url]} with invalid date"
      else
        published_on_precision = DateTimePrecision.precision(recommendation['topicYear'].to_s.split(/[-, :T]/).map(&:to_i))
      end

      update_or_create_artifact!(
        cedar_id,
        remote_identifier: id.to_s,
        title: recommendation['title'],
        description_html: recommendation['clinical'],
        url: general_rec[:url],
        published_on: date,
        published_on_precision: published_on_precision,
        artifact_type: 'General Recommendation',
        artifact_status: 'active',
        keywords: general_rec[:keywords],
        strength_of_recommendation_sort: strength_sort,
        quality_of_evidence_sort: strength_sort,
        warnings: warnings
      )
    end

    # Extract tools
    @json_data['tools'].each_pair do |id, tool|
      general_rec = tool_general_rec_info[id.to_s]
      if general_rec.nil?
        Rails.logger.warn "Skipping USPSTF tool (#{tool['title']}) with a missing parent general recommendation"
        next
      end

      url = tool['url']
      if url.empty?
        Rails.logger.warn "Skipping USPSTF tool (#{tool['title']}) with missing URL"
        next
      end

      cedar_id = "USPSTF-#{Digest::MD5.hexdigest(url.to_s)}"
      metadata = {
        title: tool['title'],
        url: url,
        artifact_type: 'Tool',
        artifact_status: 'active'
      }
      metadata.merge!(extract_metadata(url))
      # merge/deep_merge don't concat.uniq arrays so we can't set them in metadata above
      metadata[:keywords] ||= []
      metadata[:keywords].concat(general_rec[:keywords]).uniq! if general_rec.present?
      update_or_create_artifact!(cedar_id, metadata)
    end
  end

  def compute_strength_of_evidence_score(uspstf_grade)
    case uspstf_grade
    when 'A'
      2
    when 'B', 'D'
      1
    else
      0
    end
  end
end
