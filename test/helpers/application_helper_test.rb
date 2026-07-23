require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "inject_highlights returns html_safe string when highlights are empty" do
    html = "<p>Hello <strong>world</strong></p>"
    result = inject_highlights(html, [])
    assert result.html_safe?
    assert_equal html, result
  end

  test "inject_highlights highlights text nodes correctly and returns html_safe string" do
    html = "<p>Hello world from Lumen Space</p>"
    highlight = Struct.new(:id, :selected_text, :style).new(1, "world", "yellow")
    result = inject_highlights(html, [ highlight ])
    assert result.html_safe?
    assert_includes result, '<span class="highlight highlight--yellow" data-highlight-id="1">world</span>'
  end
end
