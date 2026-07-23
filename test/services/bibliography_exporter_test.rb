require "test_helper"

class BibliographyExporterTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Research Project #{SecureRandom.hex(4)}")
    @artifact1 = Artifact.create!(
      project: @project,
      title: "Ruby on Rails Documentation",
      source_url: "https://rubyonrails.org",
      artifact_type: "web_page"
    )
    @artifact2 = Artifact.create!(
      project: @project,
      title: "GitHub Repository",
      source_url: "https://github.com",
      artifact_type: "raw_link"
    )
  end

  test "exports raw urls" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("raw_urls")

    assert_includes output, "https://rubyonrails.org"
    assert_includes output, "https://github.com"
  end

  test "exports markdown" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("markdown")

    assert_includes output, "* [Ruby on Rails Documentation](https://rubyonrails.org)"
    assert_includes output, "* [GitHub Repository](https://github.com)"
  end

  test "exports bibtex" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("bibtex")

    assert_includes output, "@online{"
    assert_includes output, "url = {https://rubyonrails.org}"
    assert_includes output, "title = {Ruby on Rails Documentation}"
  end

  test "exports apa" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("apa")

    assert_includes output, "Ruby on Rails Documentation."
    assert_includes output, "Retrieved"
    assert_includes output, "from https://rubyonrails.org"
  end

  test "exports csv" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("csv")

    assert_includes output, "Title,URL,Type,Created At,Tags"
    assert_includes output, "Ruby on Rails Documentation,https://rubyonrails.org"
  end

  test "exports json" do
    exporter = BibliographyExporter.new(@project)
    output = exporter.export("json")

    assert_includes output, '"url": "https://rubyonrails.org"'
    assert_includes output, '"title": "Ruby on Rails Documentation"'
  end
end
