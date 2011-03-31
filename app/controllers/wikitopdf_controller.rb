class WikitopdfController < ApplicationController

  before_filter :find_wiki
  def export
    if User.current.allowed_to?(:export_wiki_pages, @project)
      @pages = @wiki.pages.find :all, :select => "#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on",
      :joins => "LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id",
      :order => 'title'
      @pages_by_parent_id = @pages.group_by(&:parent_id)
      to_pdf
    else
      redirect_to :controller => 'wiki', :action => 'index', :id => @project, :page => nil
    end
  end

  private

  def pdf_page_hierarchy(pages, node=nil)
    content=[]
    if pages[node]
      pages[node].each do |page|
        title = page.title.downcase
        if title != "sidebar" && title != "stylesheet"
          content << '"' + url_for(:controller => 'wiki', :action => 'show', :project_id => page.project, :id => page.title) + '"'
          content += pdf_page_hierarchy(pages, page.id) if pages[page.id]
        end
      end
    end
    content
  end

  def to_pdf
    t = Time.now.strftime("%d")
    pdfname = "#{Setting.plugin_redmine_pdf_wiki['wtp_tmpdir']}/#{t}#{rand(0x100000000).to_s(36)}.pdf"
    node = @page.nil? ? nil : @page.id
    args = Setting.plugin_redmine_pdf_wiki['wtp_command'].split(' ')
    args << '--quiet'
    flg=false
    if request.headers['Cookie']
      flg=true
      value = request.headers['Cookie']
      args << '--custom-header'
      args << 'Cookie'
      args << '"' + value +'"'
    end
    if request.headers['Authorization']
      flg=true
      value = request.headers['Authorization']
      args << '--custom-header'
      args << 'Authorization'
      args << '"' + value +'"'
    end
    args << '--custom-header-propagation' if flg
    if !@page.nil?
      args << '"' + url_for(:controller => 'wiki', :action => 'show', :project_id => @page.project, :id => @page.title)  + '"'
    end
    args += pdf_page_hierarchy(@pages_by_parent_id, node)
    args << pdfname
    `#{args.join(' ')}`
    send_file pdfname, :filename => "export.pdf",
                                 :type => 'application/pdf',
                                 :disposition => 'inline'
  end

  def find_wiki
    @project = Project.find(params[:id])
    @wiki = @project.wiki
    @page = @wiki.find_page(params[:page]) unless params[:page].nil?
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    User.current = find_current_user
    @user = User.current
  end

end
