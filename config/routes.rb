#PDF plugin for REDMINE
#map.connect ':controller/:action/:id'
match 'projects/:id/wikitopdf/:action', :controller => 'wikitopdf'
