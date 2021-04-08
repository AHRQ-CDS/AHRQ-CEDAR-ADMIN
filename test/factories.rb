# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "Repository #{n}" }
  end

  factory :artifact do
    repository
    sequence(:title) { |n| "Artifact #{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:keywords) { |n| ["keyword #{n}a", "keyword #{n}b"] }
    sequence(:mesh_keywords) { |n| ["mesh keyword #{n}a", "mesh keyword #{n}b"] }
    artifact_status { 'active' }
    artifact_type { 'test' }
  end

  factory :index_activity do
  end
end

def create_repository_with_artifacts(count: 1)
  FactoryBot.create :repository do |repository|
    FactoryBot.create_list(:artifact, count, repository: repository)
  end
end
