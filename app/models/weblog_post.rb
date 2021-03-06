# This model is used to represent a weblog post. A weblog post is contained
# within a weblog, which in turn is represented by the +Weblog+ model.
# It has specified +acts_as_content_node+ from Acts::ContentNode::ClassMethods.
#
# *Specification*
#
# Attributes
#
# * +title+ - The title of the weblog post.
# * +preamble+ - The preamble of the weblog post.
# * +body+ - The body of the weblog post.
# * +weblog+ - The weblog the weblog post belongs to.
#
# Preconditions
#
# * Requires the presence of +title+.
# * Requires the presence of +body+.
# * Requires the presence of +weblog+.
#
# Child/parent type constraints
#
#  * A +WeblogPost+ only accepts +Image+ children.
#  * A +WeblogPost+ can only be inserted into +Weblog+ nodes.
#
class WeblogPost < ActiveRecord::Base
  # Adds content node functionality to weblog posts.
  acts_as_content_node(
    allowed_child_content_types: %w( Image ),
    allowed_roles_for_create:    [],
    allowed_roles_for_update:    %w( admin final_editor ),
    allowed_roles_for_destroy:   %w( admin final_editor ),
    show_in_menu:                false,
    copyable:                    false,
    nested_resource:             true
  )

  # A +WeblogPost+ belongs to a +Weblog+.
  has_parent :weblog

  # See the preconditions overview for an explanation of these validations.
  validates :title,  presence: true, length: { maximum: 255 }
  validates :body,   presence: true
  validates :weblog, presence: true

  # Alternative text for tree nodes.
  def tree_text(node)
    "#{node.publication_start_date.day}/#{node.publication_start_date.month} #{title}"
  end

  # Returns the preamble and body as the tokens for indexing.
  def content_tokens
    [preamble, body].join(' ')
  end

  # Returns a URL alias for a given +node+.
  def path_for_url_alias(node)
    "#{node.publication_start_date.year}/#{node.publication_start_date.month}/#{node.publication_start_date.day}/#{title}"
  end
end
