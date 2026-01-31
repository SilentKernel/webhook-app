module SyntaxHighlightHelper
  # Syntax highlight code content using Rouge
  # @param content [String] the code content to highlight
  # @param language [String, nil] optional language hint (json, html, xml, etc.)
  # @return [String] HTML with syntax highlighting
  def highlight_code(content, language: nil)
    return content_tag(:pre, "", class: "highlight h-full p-4 rounded overflow-x-auto text-sm") if content.blank?

    lexer = find_lexer(content, language)
    formatter = Rouge::Formatters::HTML.new
    highlighted = formatter.format(lexer.lex(content))

    content_tag(:pre, class: "highlight h-full p-4 rounded overflow-x-auto text-sm") do
      content_tag(:code, highlighted.html_safe, class: "language-#{lexer.tag}")
    end
  end

  private

  def find_lexer(content, language)
    if language
      Rouge::Lexer.find(language) || Rouge::Lexers::PlainText.new
    else
      guess_lexer(content)
    end
  end

  def guess_lexer(content)
    # Try to detect JSON
    if json_content?(content)
      return Rouge::Lexers::JSON.new
    end

    # Try to detect HTML/XML
    if html_or_xml_content?(content)
      return Rouge::Lexers::HTML.new
    end

    # Fall back to plain text
    Rouge::Lexers::PlainText.new
  end

  def json_content?(content)
    trimmed = content.strip
    (trimmed.start_with?("{") && trimmed.end_with?("}")) ||
      (trimmed.start_with?("[") && trimmed.end_with?("]"))
  end

  def html_or_xml_content?(content)
    trimmed = content.strip
    trimmed.start_with?("<") && trimmed.include?(">")
  end
end
