#PDF plugin for REDMINE
require 'redmine'
Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next unless /\.rb$/ =~ file
  require file
end

Redmine::Plugin.register :redmine_pdf_wiki do
  name 'WikiToPdf plugin'
  author 'Arnaud Martel'
  description 'Export WIKI pages to PDF file'
  version '0.0.1'

  settings :default => {'wtp_command' => "/usr/local/bin/wkhtmltopdf --print-media-type --no-outline --output-format pdf --user-style-sheet #{File.join(File.dirname(__FILE__), 'pdf.css')}"}, :partial => 'settings/wtp_settings'
end
