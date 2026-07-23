require "test_helper"

class ArtifactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Test Project")
  end

  test "create artifact via turbo_stream updates artifact-form-container with add_form" do
    assert_difference("Artifact.count", 1) do
      post project_artifacts_path(@project), params: {
        artifact: {
          artifact_type: "raw_link",
          source_url: "https://example.com",
          title: "https://example.com"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match 'target="artifact-form-container"', response.body
    assert_match 'action="update"', response.body
    assert_match "add-form", response.body
    assert_match "artifact[source_url]", response.body
  end
end
