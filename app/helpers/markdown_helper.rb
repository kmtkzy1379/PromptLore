module MarkdownHelper
  class RougeRenderer < Redcarpet::Render::HTML
    def block_code(code, language)
      language ||= "text"
      formatter = Rouge::Formatters::HTML.new
      lexer = Rouge::Lexer.find_fancy(language) || Rouge::Lexers::PlainText.new
      %(<div class="highlight"><pre>#{formatter.format(lexer.lex(code))}</pre></div>)
    end
  end

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
    markdown.render(text).html_safe
  end
end
