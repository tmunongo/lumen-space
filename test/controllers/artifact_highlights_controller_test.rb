require "test_helper"

class ArtifactHighlightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @project = Project.create!(name: "Test Highlight Project")
    @artifact = @project.artifacts.create!(
      artifact_type: "web_page",
      title: "Sample Article",
      source_url: "https://example.com/article",
      content: "Hello world text content for testing highlights."
    )
  end

  test "create highlight via turbo stream creates highlight and updates content" do
    assert_difference -> { @artifact.highlights.count }, 1 do
      post project_artifact_highlights_path(@project, @artifact), params: {
        artifact_highlight: {
          selected_text: "world",
          style: "yellow"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match 'target="artifact_' + @artifact.id.to_s + '_content"', response.body
    assert_match "highlight--yellow", response.body
  end

  test "destroy highlight via turbo stream deletes highlight and updates content" do
    highlight = @artifact.highlights.create!(selected_text: "world", style: "yellow")

    assert_difference -> { @artifact.highlights.count }, -1 do
      delete project_artifact_highlight_path(@project, @artifact, highlight), as: :turbo_stream
    end

    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match 'target="artifact_' + @artifact.id.to_s + '_content"', response.body
  end
end
