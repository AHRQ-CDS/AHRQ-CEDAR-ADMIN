# frozen_string_literal: true

FactoryBot.define do
  factory :ip_lookup

  factory :user do
    username { 'Dummy' }
  end

  factory :search_log do
    search_params { { '_content' => 'statin', 'artifact-current-state' => 'active' } }
    count { 10 }
    total { 27 }
    returned_artifact_ids { [2565, 2989, 2943, 3086, 3087, 2945, 2944, 2306, 508, 3036] }
    client_ip { '192.168.1.1' }
    start_time = Time.zone.now
    start_time { start_time }
    end_time { start_time + 1.second }
  end

  factory :repository do
    sequence(:name) { |n| "Repository #{n}" }
    sequence(:alias) { |n| "Alias #{n}" }
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
    sequence(:umls_description) { |n| "Description #{n}" }
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

  factory :mesh_tree_node do
    sequence(:tree_number) { |n| "Tree Number #{n}" }
    sequence(:code) { |n| "Code #{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:name) { |n| "Name #{n}" }
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
