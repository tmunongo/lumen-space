require "test_helper"

class WebFetchJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  setup do
    @project = Project.create!(name: "Test Project")
    @artifact = @project.artifacts.create!(
      artifact_type: "raw_link",
      source_url: "https://example.com",
      title: "https://example.com",
      is_fetched: false
    )
  end

  test "perform updates artifact metadata and broadcasts turbo stream replace" do
    def HTTParty.get(url, **options)
      Struct.new(:success?, :body).new(true, "<html><head><title>Example Page</title></head><body><main><p>Hello World</p></main></body></html>")
    end

    assert_broadcasts(@project.to_gid_param, 2) do
      WebFetchJob.perform_now(@artifact.id)
    end

    @artifact.reload
    assert_equal "Example Page", @artifact.title
    assert_equal "web_page", @artifact.artifact_type
    assert_equal true, @artifact.is_fetched
    assert_includes @artifact.content, "Hello World"
  end
end
