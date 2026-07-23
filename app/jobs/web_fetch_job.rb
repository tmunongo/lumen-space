class WebFetchJob < ApplicationJob
  queue_as :default

  REMOVE_TAGS = %w[script style noscript iframe object embed nav header footer aside form].freeze
  PRESERVE_TAGS = %w[p h1 h2 h3 h4 h5 h6 strong em b i u a ul ol li blockquote pre code img figure figcaption br hr].freeze
  ALLOWED_ATTRS = { "a" => %w[href title], "img" => %w[src alt title] }.freeze

  def perform(artifact_id)
    artifact = Artifact.find_by(id: artifact_id)
    return unless artifact && artifact.source_url.present?

    begin
      response = HTTParty.get(artifact.source_url,
        headers: { "User-Agent" => "Mozilla/5.0 (compatible; LumenSpace/1.0)" },
        follow_redirects: true,
        timeout: 15)

      unless response.success?
        mark_failed(artifact, "HTTP #{response.code}")
        return
      end

      doc = Nokogiri::HTML(response.body)

      # Remove noise elements
      REMOVE_TAGS.each { |tag| doc.css(tag).remove }

      # Extract title
      title = extract_title(doc)
      title = artifact.source_url if title.blank?

      # Find main content
      content_node = extract_main_content(doc)

      # Clean and sanitize HTML
      cleaned_html = sanitize_node(content_node)

      artifact.update!(
        title: title,
        content: cleaned_html,
        is_fetched: true,
        artifact_type: "web_page"
      )

      broadcast_updates(artifact)
    rescue => e
      Rails.logger.error "WebFetchJob failed for artifact #{artifact_id}: #{e.message}"
      mark_failed(artifact, e.message)
    end
  end

  private

  def extract_title(doc)
    [ doc.at_css("article h1"), doc.at_css("h1"), doc.at_css("title") ]
      .compact.map { |el| el.text.strip }.reject(&:blank?).first
  end

  def extract_main_content(doc)
    doc.at_css("article") ||
    doc.at_css("main") ||
    score_best_div(doc) ||
    doc.at_css("body") ||
    doc
  end

  def score_best_div(doc)
    best, best_score = nil, 0
    doc.css("div").each do |div|
      score = div.css("p").count * 3 + div.text.length / 100.0
      id_class = "#{div['class']} #{div['id']}".downcase
      score -= 50 if id_class.match?(/comment|footer|nav|sidebar/)
      score += 25 if id_class.match?(/article/)
      score += 20 if id_class.match?(/main|content/)
      if score > best_score
        best_score = score
        best = div
      end
    end
    best
  end

  def sanitize_node(node)
    return "" unless node
    buffer = +""
    traverse(node, buffer)
    buffer.strip
  end

  def traverse(node, buffer)
    if node.text?
      text = node.text.strip
      buffer << text unless text.blank?
    elsif node.element?
      tag = node.name.downcase
      return if REMOVE_TAGS.include?(tag)

      if PRESERVE_TAGS.include?(tag)
        attrs = build_attrs(tag, node)
        buffer << "<#{tag}#{attrs}>"
        node.children.each { |child| traverse(child, buffer) }
        buffer << "</#{tag}>"
      else
        node.children.each { |child| traverse(child, buffer) }
      end
    end
  end

  def build_attrs(tag, node)
    allowed = ALLOWED_ATTRS[tag] || []
    attrs = allowed.filter_map do |attr|
      val = node[attr]
      next unless val.present?
      next if %w[href src].include?(attr) && dangerous_url?(val)
      " #{attr}=\"#{ERB::Util.html_escape(val)}\""
    end
    attrs.join
  end

  def dangerous_url?(url)
    url.to_s.strip.downcase.start_with?("javascript:", "vbscript:", "data:text")
  end

  def broadcast_updates(artifact)
    project = artifact.project
    return unless project

    Turbo::StreamsChannel.broadcast_replace_to(
      project,
      target: "artifact_#{artifact.id}",
      partial: "artifacts/artifact_item",
      locals: { artifact: artifact, project: project }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      project,
      target: "artifact_#{artifact.id}_reader_wrapper",
      partial: "artifacts/reader_wrapper",
      locals: { artifact: artifact, project: project }
    )
  end

  def mark_failed(artifact, reason)
    Rails.logger.warn "WebFetchJob: failed for #{artifact&.id}: #{reason}"
    return unless artifact && artifact.project

    Turbo::StreamsChannel.broadcast_replace_to(
      artifact.project,
      target: "artifact_#{artifact.id}_status",
      partial: "artifacts/fetch_status",
      locals: { artifact: artifact, fetching: false }
    )
  end
end
