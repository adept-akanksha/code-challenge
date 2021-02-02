require 'securerandom'
require 'erb'

class HtmlBuilder
  OUTPUT_FILE_PATH = (__dir__ + '/output.html').freeze
  TEMPLATE_FILE_PATH = (__dir__ + '/highlighting_template.html.erb').freeze

  attr_reader :content, :highlights, :highlighted_html

  def initialize(content, highlights)
    @content = content
    @highlights = highlights
  end

  def call
    assign_highlights_color_codes
    highlight_text
    split_html_paragraphs
    wrap_in_html_body
    create_html_file
  end

  private

  def assign_highlights_color_codes
    color_codes = []
    index = 0

    while index < highlights.size
      new_code = SecureRandom.hex(3)
      next if color_codes.include?(new_code)

      color_codes << new_code
      highlights[index][:color_code] = new_code
      index += 1
    end
  end

  def highlight_text
    words = content.split(/ /)

    highlights.each do |highlighting_data|
      words[highlighting_data[:start]] = prepend_html_to_highlight_starting_word(
        words[highlighting_data[:start]],
        highlighting_data[:comment],
        highlighting_data[:color_code]
      )

      words[highlighting_data[:end] - 1] = append_html_to_highlight_ending_word(
        words[highlighting_data[:end] - 1]
      )
    end

    @highlighted_html = words.join(' ')
  end

  def prepend_html_to_highlight_starting_word(word, data_text, color_code)
    '<mark class="tooltip" data-text="' +
      data_text +
      '" style="background-color: #' +
      color_code + '">' +
      word
  end

  def append_html_to_highlight_ending_word(word)
    word + '</mark>'
  end

  def split_html_paragraphs
    @highlighted_html = @highlighted_html
      .split("\n\n")
      .map { |para| "<p>#{para}</p>" }
      .join("\n\t\t")
  end

  def wrap_in_html_body
    @highlighted_html = ERB.new(
      File.read(TEMPLATE_FILE_PATH)
    ).result(binding)
  end

  def create_html_file
    File.open(OUTPUT_FILE_PATH, 'w') { |f| f.write(@highlighted_html) }
    puts "String parsed successfully to HTML text"
    puts "Run `open #{OUTPUT_FILE_PATH}` to see the output."
  end
end
