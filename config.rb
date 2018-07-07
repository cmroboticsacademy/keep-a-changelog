# --------------------------------------
#   Config
# --------------------------------------

# ----- Site ----- #
# Last version should be the latest English version since the manifesto is first
# written in English, then translated into other languages later.
$versions = (Dir.entries("source/en") - %w[. ..])
$last_version = $versions.last
$previous_version = $versions[$versions.index($last_version) - 1]

# This list of languages populates the language navigation.
issues_url = 'https://github.com/cmroboticsacademy/keep-a-changelog/issues'
$languages = {
  "en"    => {
    default: true,
    name: "English",
    new: "A new version is available"
  }
}

activate :i18n,
  lang_map: $languages,
  mount_at_root: :en

set :gauges_id, ''
set :publisher_url, 'https://www.facebook.com/olivier.lacan.5'
set :site_url, 'https://changelog.cs2n.org'

redirect "index.html", to: "en/#{$last_version}/index.html"

$languages.each do |language|
  code = language.first
  versions = Dir.entries("source/#{code}") - %w[. ..]
  redirect "#{code}/index.html", to: "#{code}/#{versions.last}/index.html"
end

# ----- Assets ----- #

set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'
set :images_dir, 'assets/images'
set :fonts_dir, 'assets/fonts'

# ----- Images ----- #

activate :automatic_image_sizes

# ----- Markdown ----- #

activate :syntax
set :markdown_engine, :redcarpet

## Override default Redcarpet renderer in order to define a class
class CustomMarkdownRenderer < Redcarpet::Render::HTML
  def doc_header
    %Q[<nav role="navigation" class="toc">#{@header}</nav>]
  end

  def header(text, header_level)
    slug = text.parameterize
    tag_name = "h#{header_level}"
    anchor_link = "<a id='#{slug}' class='anchor' href='##{slug}' aria-hidden='true'></a>"
    header_tag_open = "<#{tag_name} id='#{slug}'>"

    output = ""
    output << header_tag_open
    output << anchor_link
    output << text
    output << "</#{tag_name}>"

    output
  end
end

$markdown_config = {
  fenced_code_blocks: true,
  footnotes: true,
  smartypants: true,
  tables: true,
  with_toc_data: true,
  renderer: CustomMarkdownRenderer
}
set :markdown, $markdown_config

# --------------------------------------
#   Helpers
# --------------------------------------

helpers do
  def path_to_url(path)
    Addressable::URI.join(config.site_url, path).normalize.to_s
  end

  def available_translation_for(language)
    language_name = language.last[:name]
    language_path = "source/#{language.first}"

    if File.exists?("#{language_path}/#{$last_version}")
      "#{$last_version} #{language_name}"
    elsif File.exists?("#{language_path}/#{$previous_version}")
      "#{$previous_version} #{language_name}"
    else
      nil
    end
  end
end

# --------------------------------------
#   Content
# --------------------------------------

# ----- Directories ----- #

activate :directory_indexes
page "/404.html", directory_index: false

# --------------------------------------
#   Production
# --------------------------------------

# ----- Optimization ----- #

configure :build do
  set :gauges_id, "5389808eeddd5b055a00440d"
  activate :asset_hash
  activate :gzip, {exts: %w[
    .css
    .eot
    .htm
    .html
    .ico
    .js
    .json
    .svg
    .ttf
    .txt
    .woff
  ]}
  set :haml, { attr_wrapper: '"' }
  activate :minify_css
  activate :minify_html do |html|
    html.remove_quotes = false
  end
  activate :minify_javascript
end

# ----- Prefixing ----- #

activate :autoprefixer do |config|
  config.browsers = ['last 2 versions', 'Explorer >= 10']
  config.cascade  = false
end

# Haml doesn't pick up on Markdown configuration so we have to remove the
# default Markdown Haml filter and reconfigure one that follows our
# global configuration.

module Haml::Filters
  remove_filter("Markdown") #remove the existing Markdown filter

  module Markdown
    include Haml::Filters::Base

    def renderer
      $markdown_config[:renderer]
    end

    def render(text)
      Redcarpet::Markdown.new(renderer.new($markdown_config)).render(text)
    end
  end
end
