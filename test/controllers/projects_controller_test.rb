require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Export Test Project #{SecureRandom.hex(4)}")
    @artifact = Artifact.create!(
      project: @project,
      title: "Sample Web Page",
      source_url: "https://example.org",
      artifact_type: "web_page"
    )
  end

  test "export via turbo stream renders modal partial" do
    get export_project_path(@project, export_format: "markdown"), as: :turbo_stream

    assert_response :success
    assert_match "export-modal", response.body
    assert_match "Export Links & Bibliography", response.body
    assert_match "* [Sample Web Page](https://example.org)", response.body
  end

  test "export format text downloads text file" do
    get export_project_path(@project, format: :text, export_format: "raw_urls")

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "https://example.org"
  end

  test "export format csv downloads csv file" do
    get export_project_path(@project, format: :csv, export_format: "csv")

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Sample Web Page,https://example.org"
  end

  test "export format json downloads json file" do
    get export_project_path(@project, format: :json, export_format: "json")

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, '"url": "https://example.org"'
  end
end
