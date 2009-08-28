# Parses an html file's <head> section,
# looks for <script ... > and <link rel="stylesheet" ... >
# and crunches them all together into one file
# 
# Warning: this script is super-ghetto and probably not robust.
# If you're concerned, use a real lexer/parser.

require 'strscan'

module HtmlAssetCrush
  def self.source_for(asset_path)
    case asset_path
    when /js$/
      <<-JS
      <script type="text/javascript" charset="utf-8">
        #{File.open(asset_path).read}
      </script>
      JS
    when /css$/
      <<-CSS
      <style type="text/css">
        #{File.open(asset_path).read}
      </style>
      CSS
    end
  rescue Errno::ENOENT
    raise "Could not find #{asset_path} to bring in"
  end
  
  def self.crush(html_filepath)
    Dir.chdir(File.dirname(html_filepath)) do
      html = File.open(html_filepath).read
      crushed_html = ""    

      s = StringScanner.new(html)

      js = /<script.+? src=['"](.+)['"].+?\/script>/
      css = /<link .+? href=['"](.+?)['"].+?>/
      asset = Regexp.union(js, css)

      while result = s.scan_until(asset) do
        asset_path = s[2] || s[1]

        # Weird that pre_match doesn't do this
        # crushed_html << s.pre_match
        crushed_html << result[0...(-s.matched_size)]

        crushed_html << source_for(asset_path) + "\n"
      end

      crushed_html << s.rest

      return crushed_html
    end
  end
end