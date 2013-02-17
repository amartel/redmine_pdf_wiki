module Wikitopdf

  # PDF export via wkhtmltopdf
  class PdfExport
  
    def initialize(page, project, controller)
      @page = page
      @project = project
      @request = controller.request
      @controller = controller
      @wiki = @project.wiki
      @tmpdir = Rails.root.join('tmp', 'pdf')
      raise 'No wiki page found' unless @wiki
    end
  
    def export
      @pages = @wiki.pages.find :all, :select => "#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on",
      :joins => "LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id",
      :order => 'title'
      @pages_by_parent_id = @pages.group_by(&:parent_id)
      to_pdf
    end
    
    private
    
    def url_for hash
      @controller.url_for hash
    end

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
      
      pdfname = "#{@tmpdir}/#{t}#{rand(0x100000000).to_s(36)}.pdf"
      node = @page.nil? ? nil : @page.id
      #args = Setting.plugin_redmine_pdf_wiki['wtp_command'].split(' ')
      #args << '--quiet'

      args = [ '--quiet' ]

      flg=false
      if @request.headers['Cookie']
        flg=true
        value = @request.headers['Cookie']
        args << '--custom-header'
        args << 'Cookie'
        args << '"' + value +'"'
      end
      if @request.headers['Authorization']
        flg=true
        value = @request.headers['Authorization']
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

      cmdname = "#{@tmpdir}/#{t}#{rand(0x100000000).to_s(36)}.txt"
      File.open(cmdname, "w") do |f|
        f.write(args.join(' '))
      end

      `#{Setting.plugin_redmine_pdf_wiki['wtp_command']} --read-args-from-stdin < #{cmdname}`
      
      IO.read(pdfname)
    ensure
      safe_unlink cmdname 
      safe_unlink pdfname
    end
  
    # unlink that never throws
    def safe_unlink filename
      return unless filename
      begin
        File.unlink filename
      rescue => e
        Rails.logger.warn("Cannot unlink temp file " + filename) if logger && logger.debug?
      end
    end
    
  end

  # Module for patching native PDF engine
  module PDFPatch
    
    def self.included(base)
      base.send(:include, ModuleMethods)
    end
  
    module ModuleMethods
      # Patched WikiController method, returns PDF body
      def wiki_page_to_pdf(page, project)
        Rails.logger.debug("Invoked patched wiki_page_to_pdf") if logger && logger.debug?
        pdf_export = Wikitopdf::PdfExport.new(page, project, self)
        pdf_export.export
      end
    end
  end
        
end
