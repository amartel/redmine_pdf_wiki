#PDF plugin for REDMINE
require 'redmine'

Redmine::Plugin.register :redmine_pdf_wiki do
  name 'WikiToPdf plugin'
  author 'Arnaud Martel'
  description 'Export wiki pages to PDF file'
  version '0.0.4'
  
  # due to Dispatcher changes
  requires_redmine :version_or_higher => '2.0.0'

  settings :default => {'wtp_command' => "/usr/local/bin/wkhtmltopdf --print-media-type --no-outline  --disable-external-links --disable-internal-links -n --output-format pdf --load-error-handling ignore --user-style-sheet #{File.join(File.dirname(__FILE__), 'pdf.css')}"}, :partial => 'settings/wtp_settings'
end

require 'wikitopdf'
ActionDispatch::Callbacks.to_prepare do
  WikiController.send(:include, Wikitopdf::PDFPatch)
end
