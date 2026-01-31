# frozen_string_literal: true

require "test_helper"

class SyntaxHighlightHelperTest < ActionView::TestCase
  # JSON highlighting tests
  test "highlight_code highlights JSON content" do
    json = '{"key": "value", "number": 123}'
    result = highlight_code(json, language: "json")

    assert_match(/class="highlight/, result)
    assert_match(/language-json/, result)
    assert_match(/key/, result)
    assert_match(/value/, result)
  end

  test "highlight_code auto-detects JSON objects" do
    json = '{"name": "test"}'
    result = highlight_code(json)

    assert_match(/language-json/, result)
  end

  test "highlight_code auto-detects JSON arrays" do
    json = '[1, 2, 3]'
    result = highlight_code(json)

    assert_match(/language-json/, result)
  end

  # HTML highlighting tests
  test "highlight_code highlights HTML content" do
    html = "<html><body><h1>Hello</h1></body></html>"
    result = highlight_code(html, language: "html")

    assert_match(/class="highlight/, result)
    assert_match(/language-html/, result)
  end

  test "highlight_code auto-detects HTML content" do
    html = "<div class='test'>Content</div>"
    result = highlight_code(html)

    assert_match(/language-html/, result)
  end

  # XML highlighting tests
  test "highlight_code highlights XML content" do
    xml = '<?xml version="1.0"?><root><item>Test</item></root>'
    result = highlight_code(xml, language: "xml")

    assert_match(/class="highlight/, result)
    assert_match(/language-xml/, result)
  end

  # Plain text fallback
  test "highlight_code falls back to plain text for unrecognized content" do
    text = "Plain text without any markers"
    result = highlight_code(text)

    assert_match(/class="highlight/, result)
    assert_match(/language-plaintext/, result)
  end

  # Empty/nil content handling
  test "highlight_code handles nil content" do
    result = highlight_code(nil)

    assert_match(/class="highlight/, result)
    assert_match(/<pre/, result)
  end

  test "highlight_code handles empty string" do
    result = highlight_code("")

    assert_match(/class="highlight/, result)
    assert_match(/<pre/, result)
  end

  test "highlight_code handles whitespace-only content" do
    result = highlight_code("   ")

    assert_match(/class="highlight/, result)
  end

  # Structure tests
  test "highlight_code wraps content in pre and code tags" do
    json = '{"test": true}'
    result = highlight_code(json, language: "json")

    assert_match(/<pre[^>]*>.*<code[^>]*>.*<\/code>.*<\/pre>/m, result)
  end

  test "highlight_code includes overflow classes" do
    json = '{"test": true}'
    result = highlight_code(json, language: "json")

    assert_match(/overflow-x-auto/, result)
  end

  # Specific language detection
  test "highlight_code uses specified language over auto-detection" do
    content = '{"looks": "like json"}'
    result = highlight_code(content, language: "plaintext")

    assert_match(/language-plaintext/, result)
  end

  # Edge cases
  test "highlight_code handles JSON with whitespace padding" do
    json = "  {\"key\": \"value\"}  "
    result = highlight_code(json)

    assert_match(/language-json/, result)
  end

  test "highlight_code handles HTML with whitespace padding" do
    html = "  <div>Test</div>  "
    result = highlight_code(html)

    assert_match(/language-html/, result)
  end
end
