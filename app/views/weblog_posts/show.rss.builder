xml << render(:partial => 'shared/feed', :locals => { :items => @comments, :content_node => @weblog_post })
