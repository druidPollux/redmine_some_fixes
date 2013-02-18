require 'redmine'
require 'redmine_some_fixes/hooks'

Redmine::Plugin.register :redmine_some_fixes do
  name 'Some fixes'
  author 'Roman Shipiev'
  description 'The plugin trancate project name to 30 chars in all project selects, links to projects, in headers'
  version '0.0.4'
  url 'https://github.com/rubynovich/redmine_some_fixes'
  author_url 'http://roman.shipiev.me'

  settings :default => {
    :wrap_length => 60,
    :tranc_length => 60
  }
end

require_dependency 'application_helper'

ActionView::Base.class_eval do
  include ApplicationHelper

  def link_to_project_with_tranc(project, options={}, html_options = nil)
    project_name = word_wrap(
      h(project),
      :line_width => Setting[:plugin_redmine_some_fixes][:wrap_length]
    ).gsub(/\n/){ "<br />" }.html_safe
    if project.active?
      url = {:controller => 'projects', :action => 'show', :id => project}.merge(options)
      link_to(project_name, url, html_options)
    else
      h(project_name)
    end
  end

  def project_tree_options_for_select_with_tranc(projects, options = {})
    s = ''
    project_tree(projects) do |project, level|
      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => project.id}
      if project == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(project))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag_options.merge!(yield(project)) if block_given?
      s << content_tag('option',
        truncate(name_prefix + h(project),
          :length => Setting[:plugin_redmine_some_fixes][:tranc_length],
          :separator => ' ').html_safe,
        tag_options)
    end
    s.html_safe
  end

  alias_method_chain :link_to_project, :tranc
  alias_method_chain :project_tree_options_for_select, :tranc
end
