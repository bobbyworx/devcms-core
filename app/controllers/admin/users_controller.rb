# This administrative controller is used to manage the website users. It is
# set up to communicate with ExtJS components using XML.
class Admin::UsersController < Admin::AdminController
  before_filter :find_user, :except => [:index, :create, :privileged, :invite, :last_sign_ins]
  before_filter :set_paging,  :only => [:index, :create, :privileged]
  before_filter :set_sorting, :only => [:index, :create, :privileged]

  skip_before_filter :set_actions
  skip_before_filter :find_node

  require_role ['admin', 'final_editor']

  # * GET /admin/users
  # * GET /admin/users.xml
  # * GET /admin/users.json
  def index
    @active_page ||= :users
    @roles ||= current_user.role_assignments.map { |role_assignment| role_assignment.name }
    user_scope = (@active_page == :privileged_users) ? PrivilegedUser.scoped : User.exclusive

    respond_to do |format|
      format.html do
        find_users(user_scope)
        render :action => :index
      end
      format.xml do
        find_users(user_scope)
        render :action => :index, :layout => false
      end
      format.json do
        users = User.select('users.login, users.id').where(["users.login LIKE ?", "#{params[:query]}%"])
        render :json => { :users => users }.to_json, :status => :ok
      end
      format.csv do
        @users = user_scope
        render :action => :index, :layout => false
      end
    end
  end

  # * GET /admin/users/last_sign_in.csv
  def last_sign_ins
    respond_to do |format|
      format.csv do
        @users = User.joins('left outer join login_attempts on login_attempts.user_login = users.login and login_attempts.success = true').joins('left outer join newsletter_archives_users on users.id = newsletter_archives_users.user_id').select('users.id, users.type, users.email_address, max(login_attempts.created_at) AS last_sign_in_at, count(newsletter_archives_users.user_id) as newsletter_subscription_count').group('users.id, users.email_address, users.type')
        render :action => :last_sign_ins, :layout => false
      end
    end
  end

  # * GET /admin/users/privileged.json
  def privileged
    @active_page = :privileged_users

    respond_to do |format|
      format.html { index }
      format.xml  { index }
      format.csv  { index }
      format.json do
        node = Node.find(params[:node])
        users = PrivilegedUser.select('users.login, users.id').includes(:role_assignments).where(["users.login LIKE ? AND role_assignments.node_id IN (?) AND role_assignments.name in (?)", "#{params[:query]}%", node.path_ids, ['editor', 'final_editor']])
        render :json => { :users => users }.to_json, :status => :ok
      end
    end
  end

  # * PUT /admin/users/1
  # * PUT /admin/users/1.xml
  def update
    params[:user][:newsletter_archive_ids] ||= []
    params[:user][:interest_ids] ||= []

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html do
          flash[:notice] = I18n.t('users.user_update_succesful')
          redirect_to admin_users_path
        end
        format.xml  { head :ok }
        format.json { render :json => { :success => 'true' } }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml  => @user.errors, :status => :unprocessable_entity }
        format.json { render :json => @user.errors.full_messages.join(' '), :status => :unprocessable_entity }
      end
    end
  end

  # * DELETE /admin/users/1
  # * DELETE /admin/users/1.json
  #
  # This method ensures that the current user cannot be deleted.
  def destroy
    respond_to do |format|
      if @user == current_user
        error = I18n.t('users.cant_destroy_yourself')
        @user.errors.add(:base, error)

        format.html do
          flash[:error] = error
          redirect_to admin_users_path
        end
        format.json { render :json => { :errors => @user.errors.full_messages }.to_json, :status => :unprocessable_entity }
      else
        @user.destroy
        format.html { redirect_to admin_users_path }
        format.json { head :ok }
      end
    end
  end

  # * GET /admin/users/1/accessible_newsletter_archives.json
  #
  def accessible_newsletter_archives
    respond_to do |format|
      format.json do
        newsletter_archives = NewsletterArchive.accessible.all(:select => "#{NewsletterArchive.quoted_table_name}.id, #{NewsletterArchive.quoted_table_name}.title", :order => 'newsletter_archives.title')
        newsletter_archives = newsletter_archives.map do |na|
          {
            :id      => na.id,
            :title   => na.title,
            :checked => @user.newsletter_archives.include?(na)
          }
        end
        render :json => { :newsletter_archives => newsletter_archives, :success => true, :total_count => newsletter_archives.size }.to_json, :status => :ok
      end
    end
  end

  # * GET /admin/users/:id/interests.json
  #
  def interests
    respond_to do |format|
      format.json do
        interests = Interest.order('title').all.map do |i|
          {
            :id      => i.id,
            :title   => i.title,
            :checked => @user.interests.include?(i)
          }
        end
        render :json => { :interests => interests, :success => true, :total_count => interests.size }.to_json, :status => :ok
      end
    end
  end

  def invite
    respond_to do |format|
      if User.send_invitation_email!(params[:email_address])
        format.json { render :json => { :success => 'true' } }
      else
        format.json { render :json => { :errors => t('users.invalid_email_address') }.to_json, :status => :unprocessable_entity }
      end
    end
  end

  # * POST /admin/users
  # * POST /admin/users.xml
  #
  # This method does not actually implement a create action. It serves to
  # satisfy the ExtJS PagingToolbar, which sends its current page using the
  # POST method. This is delegated to the index method.
  def create
    if extjs_paging? || extjs_sorting?
      index
    end
  end

  def switch_user_type
    respond_to do |format|
      format.json do
        if @user.is_privileged?
          @user.demote!
          render :json => { :success => 'true' }
        else
          @user.promote!
          render :json => { :success => 'true' }
        end
      end
    end
  end

  def revoke
    respond_to do |format|
      format.json do
        if @user.update_column :blocked, false
          render :json => { :success => 'true' }
        else
          render :json => { :status => :unprocessable_entity }
        end
      end
    end
  end

  protected

    def find_users(user_scope = User.scoped)
      if !@sort_by_newsletter_archives
        # Don't eager load newsletter_archives lest the XML builder will fail.
        # This may be resolved by transforming this controller into JSON or in
        # a version of Rails > 2.0.2.
        @sort_field = 'users.created_at' if @sort_field == 'created_at'

        user_scope  = user_scope.includes([ :newsletter_archives, :interests ]).where(filter_conditions).order("#{@sort_field} #{@sort_direction}")      
        @user_count = user_scope.count
        @users      = user_scope.page(@current_page).per(@page_limit)
      else
        @users      = user_scope.includes([ :newsletter_archives, :interests ]).where(filter_conditions).order("login #{@sort_direction}")
        @users      = @users.sort_by { |user| user.newsletter_archives.sort_by { |archive| archive.title.upcase }.map { |archive| archive.title }.join(', ') }
        @users      = @users.reverse if @sort_direction == 'DESC'
        @user_count = @users.size
        @users      = @users.values_at((@page_limit * (@current_page - 1))..(@page_limit * @current_page - 1)).compact
      end
    end

    def find_user
      @user = User.find(params[:id])
    end

    # Finds sorting parameters.
    def set_sorting
      if extjs_sorting?
        @sort_direction = (params[:dir] == 'ASC' ? 'ASC' : 'DESC')

        # We can't sort the newsletter subscriptions in SQL...
        if params[:sort].include?('newsletter_archives')
          @sort_by_newsletter_archives = true
        else
          # ...but we can sort all non-polymorphic relationships
          @sort_field = ActiveRecord::Base.connection.quote_column_name(params[:sort])
        end
      else
        @sort_field = 'login'
      end
      @sort_field = "UPPER(#{@sort_field})" unless @sort_field =~ /(id|created_at)/
    end

    # Checks whether some filters are defined in Ext.
    # If not, don't return any new conditions, otherwise,
    # generate the conditions defined by the filters
    def filter_conditions
      if params[:filter]
        generate_filter_conditions
      else
        []
      end
    end

    # Generates SQL conditions based on the filter parameter
    def generate_filter_conditions
      filters = params[:filter]
      conditions = filters.keys.map do |key|
        filter      = filters[key]
        filterType  = filter[:data][:type]
        filterValue = filter[:data][:value]
        filterField = 'users.' + filter[:field]
        case filterType
          when 'string'
            [ filterField + ' LIKE ?', filterValue + '%']
          when 'list'
            sex = (filterValue == I18n.t('users.male')) ? 'm' : 'f'
            [ filterField + ' = ?', sex]
          when 'date'
            comparison = filter[:data][:comparison]
            date = DateTime.strptime(filterValue, "%m/%d/%Y")
            if comparison == 'gt'
              [ filterField + ' > ?', date ]
            elsif comparison == 'lt'
              [ filterField + ' < ?', date ]
            elsif comparison == 'eq'
              [ filterField + ' BETWEEN ? AND ? ', date, date + 1.days]
            end
          else
            [ filterField + ' = ?', filterValue ]
        end
      end

      [conditions.map { |condition| condition.first }.join(' AND ')] + conditions.map { |condition| condition.last(condition.size - 1) }.flatten
    end
end
