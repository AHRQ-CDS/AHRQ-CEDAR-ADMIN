# frozen_string_literal: true

class PageScraperTest < ActiveSupport::TestCase
  include PageScraper

  test 'Scrap EPC date' do
    artifact_mock = file_fixture('epc_date_artifact.html').read

    stub_request(:get, 'http://example.com/test').to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: artifact_mock)

    metadata = extract_metadata('http://example.com/test')

    assert metadata.present?
    assert metadata[:published_on].present?
  end
end
