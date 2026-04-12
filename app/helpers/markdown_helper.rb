module MarkdownHelper
  class RougeRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      language ||= "text"
      formatter = Rouge::Formatters::HTML.new
      lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
      %(<div class="highlight"><pre>#{formatter.format(lexer.lex(code))}</pre></div>)
    end
  end

  ALLOWED_TAGS = %w[p br h1 h2 h3 h4 h5 h6 ul ol li a code pre div span
                     table thead tbody tr th td strong em del blockquote hr img].freeze
  ALLOWED_ATTRS = %w[href src alt title class].freeze

  def render_markdown(text)
    renderer = RougeRenderer.new(hard_wrap: true, filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer,
      fenced_code_blocks: true,
      tables: true,
      autolink: true,
      strikethrough: true,
      no_intra_emphasis: true,
      lax_spacing: true
    )
    html = markdown.render(text)
    sanitized = Rails::HTML5::SafeListSanitizer.new.sanitize(
      html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS
    )
    sanitized.gsub!(/href\s*=\s*["']?\s*javascript:/i, 'href="')
    sanitized.gsub!(/src\s*=\s*["']?\s*javascript:/i, 'src="')
    sanitized.html_safe
  end
end
