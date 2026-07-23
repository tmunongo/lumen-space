class BibliographyExporter
  FORMATS = %w[raw_urls markdown bibtex apa csv json].freeze

  def initialize(project)
    @project = project
  end

  def export(format = "markdown")
    artifacts_with_links = @project.artifacts.where.not(source_url: [ nil, "" ]).order(created_at: :asc)

    case format.to_s.downcase
    when "raw_urls"
      export_raw_urls(artifacts_with_links)
    when "markdown"
      export_markdown(artifacts_with_links)
    when "bibtex"
      export_bibtex(artifacts_with_links)
    when "apa"
      export_apa(artifacts_with_links)
    when "csv"
      export_csv(artifacts_with_links)
    when "json"
      export_json(artifacts_with_links)
    else
      export_markdown(artifacts_with_links)
    end
  end

  private

  def export_raw_urls(artifacts)
    artifacts.map(&:source_url).join("\n")
  end

  def export_markdown(artifacts)
    artifacts.map { |a| "* [#{a.title.presence || a.source_url}](#{a.source_url})" }.join("\n")
  end

  def export_bibtex(artifacts)
    artifacts.map.with_index(1) do |a, idx|
      key = generate_bibtex_key(a, idx)
      title = sanitize_bibtex(a.title.presence || a.source_url)
      date = a.created_at.strftime("%Y-%m-%d")
      year = a.created_at.year

      <<~BIBTEX.strip
        @online{#{key},
          title = {#{title}},
          url = {#{a.source_url}},
          urldate = {#{date}},
          year = {#{year}}
        }
      BIBTEX
    end.join("\n\n")
  end

  def export_apa(artifacts)
    artifacts.map do |a|
      title = a.title.presence || "Untitled"
      year = a.created_at.year
      date_str = a.created_at.strftime("%B %d, %Y")
      "#{title}. (#{year}). Retrieved #{date_str}, from #{a.source_url}"
    end.join("\n\n")
  end

  def export_csv(artifacts)
    require "csv"
    CSV.generate(headers: true) do |csv|
      csv << [ "Title", "URL", "Type", "Created At", "Tags" ]
      artifacts.each do |a|
        csv << [ a.title, a.source_url, a.artifact_type, a.created_at.iso8601, a.tag_names.join(", ") ]
      end
    end
  end

  def export_json(artifacts)
    data = artifacts.map do |a|
      {
        title: a.title,
        url: a.source_url,
        type: a.artifact_type,
        created_at: a.created_at.iso8601,
        tags: a.tag_names
      }
    end
    JSON.pretty_generate(data)
  end

  def generate_bibtex_key(artifact, idx)
    base = artifact.title.to_s.parameterize.underscore.truncate(20, omission: "").presence || "link"
    "#{base}_#{idx}"
  end

  def sanitize_bibtex(str)
    str.gsub("{", "\\{").gsub("}", "\\}").gsub("#", "\\#")
  end
end
