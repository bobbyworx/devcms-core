xml << render(:partial => 'shared/feed', :locals => { :items => @news_items, :content_node => @news_viewer })
