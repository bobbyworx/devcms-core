require File.dirname(__FILE__) + '/../test_helper'
require 'fakeweb'

class FeedWorkerTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = true

  def setup
    FakeWeb.register_uri(:get, "http://office.nedforce.nl/correct.rss", :body => get_file_as_string('files/nedforce_feed.xml'))
    
    @feed_worker = FeedWorker.new
  end

  def test_should_update_all_feeds
    Feed.create(:parent => nodes(:root_section_node), :url => "http://office.nedforce.nl/correct.rss", :created_at => 1.day.ago)

    @feed_worker.update_feeds

    Feed.all.each do |feed|
      assert_not_equal feed.updated_at, feed.created_at
    end
  end
end
