module ApplicationHelper
  def format_date(date)
    return '' unless date
    diff = Time.current - date
    if diff < 1.day then 'today'
    elsif diff < 2.days then 'yesterday'
    elsif diff < 7.days then "#{(diff / 1.day).floor}d ago"
    elsif diff < 30.days then "#{(diff / 7.days).floor}w ago"
    else date.strftime('%b %-d, %Y')
    end
  end

  def artifact_icon(artifact)
    artifact.type_icon
  end

  def markdown_to_html(text)
    return '' unless text.present?
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, link_attributes: { target: '_blank' })
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true, strikethrough: true)
    markdown.render(text).html_safe
  end

  def inject_highlights(html_content, highlights)
    return html_content if highlights.empty?
    processed = html_content.dup
    processed_texts = Set.new

    highlights.sort_by { |h| -h.selected_text.length }.each do |highlight|
      text = highlight.selected_text.strip
      next if text.blank? || processed_texts.include?(text)

      escaped_text = ERB::Util.html_escape(text)
      replacement = %(<span class="highlight highlight--#{highlight.style}" data-highlight-id="#{highlight.id}">#{escaped_text}</span>)
      # Replace only in text nodes (not inside tags)
      processed = replace_in_text_nodes(processed, escaped_text, replacement)
      processed_texts.add(text)
    end
    processed.html_safe
  end

  private

  def replace_in_text_nodes(html, search, replacement)
    # Split by HTML tags, only replace in text segments
    parts = html.split(/(<[^>]+>)/)
    parts.map.with_index do |part, i|
      if i.even? # text node
        part.sub(search, replacement)
      else # tag
        part
      end
    end.join
  end
end
