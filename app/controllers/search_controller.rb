class SearchController < ApplicationController
  before_filter :set_search_scope
  before_filter :parse_search_scope
  before_filter :set_search_engine

  def index
    @query = params[:query].try(:strip)

    @from = Date.parse(params[:from]) rescue nil
    @to   = Date.parse(params[:to])   rescue nil

    @programme = Category.root_categories.find(params[:programme]) rescue nil

    @projects = @programme ? @programme.children : []
    @project  = @projects.find(params[:project]) rescue nil if @programme
    
    @category = Category.find(params[:category]) rescue nil
    if @category
      @programme = @category.is_root_category? ? @category : @category.parent
      @project   = @category if !@category.is_root_category?
    end
    
    @advanced = params[:advanced]
    if @query || @project || @programme
      @results = Searcher(@engine).search(@query, :page => params[:page], :for => current_user, :zipcode => params[:zipcode], :from => @from, :to => @to, :programme => @programme.try(:id), :project => @project.try(:id), :sort => params[:sort], :content_types_to_include => @content_types_to_include, :content_types_to_exclude => @content_types_to_exclude, :top_node => @top_node)
    else
      @results = []
    end
  end

  def projects
    @programme = Category.root_categories.find(params[:programme_id]) rescue nil
    @projects  = @programme ? @programme.children : []
    render :partial => 'project_select'
  end

protected

  def set_search_scope
    @search_scope = @search_scopes.find { |search_scope| search_scope.second == params[:search_scope] } || @search_scopes.first
  end

  def parse_search_scope
    @top_node = Node.find(@search_scope[1].scan(/\d+/).first)
  end
  
  def set_search_engine
    @engine = params[:search_engine] if params[:search_engine].present?
    @engine = DevCMS.search_configuration[:default_search_engine] unless DevCMS.search_configuration[:enabled_search_engines].include?(@engine)
  end

end

