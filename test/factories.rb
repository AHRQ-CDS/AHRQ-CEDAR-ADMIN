# frozen_string_literal: true

FactoryBot.define do
  factory :search_log do
    url { 'MyString' }
    sql { 'MyString' }
    count { 1 }
    start_time { '2021-06-03 13:23:44' }
    end_time { '2021-06-03 13:23:44' }
  end

  factory :repository do
    sequence(:name) { |n| "Repository #{n}" }
  end

  factory :artifact do
    repository
    sequence(:title) { |n| "Artifact #{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:keywords) { |n| ["keyword #{n}a", "keyword #{n}b"] }
    artifact_status { 'active' }
    artifact_type { 'test' }
  end

  factory :concept do
    sequence(:umls_cui) { |n| "CUI#{n}" }
    sequence(:synonyms_text) { |n| ["synonym #{n}a", "synonym #{n}b", 'foo'] }
    sequence(:codes) do |n|
      [
        { system: 'MSH', code: "#{n}a", description: "synonym #{n}a" },
        { system: 'MSH', code: "#{n}b", description: "synonym #{n}b" }
      ]
    end
  end

  factory :import_run do
    repository
  end
end

def create_repository_with_artifacts(count: 1)
  FactoryBot.create :repository do |repository|
    FactoryBot.create_list(:artifact, count, repository: repository)
  end
end

def create_concepts(count: 1)
  FactoryBot.create_list(:concept, count)
end
