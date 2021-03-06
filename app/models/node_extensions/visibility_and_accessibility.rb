module NodeExtensions::VisibilityAndAccessibility
  extend ActiveSupport::Concern

  included do
    validates_inclusion_of :private, in: [false, true], allow_nil: false
    validates_inclusion_of :hidden,  in: [false, true], allow_nil: false

    attr_protected :hidden, :private

    scope :accessible, lambda { { conditions: accessibility_and_visibility_conditions } }
    scope :public,  { conditions: { 'nodes.private' => false } }
    scope :private, { conditions: { 'nodes.private' => true  } }
  end

  module ClassMethods
    def accessibility_and_visibility_conditions
      [
        'nodes.hidden = false AND nodes.publishable = true AND (:now >= nodes.publication_start_date AND (nodes.publication_end_date IS NULL OR :now <= nodes.publication_end_date))',
        { now: Time.now }
      ]
    end
  end

  def public?
    !self.private?
  end

  def is_private_or_has_private_ancestor?
    self_and_ancestors.exists?(private: true)
  end

  def has_private_ancestor?
    ancestors.exists?(private: true)
  end

  def has_hidden_ancestor?
    ancestors.exists?(hidden: true)
  end

  def top_level_private_ancestor
    self_and_ancestors.private.first
  end

  def accessible_for_user?(user = nil)
    if self_and_ancestors.sections.private.any?
      user && user.role_assignments.exists?(node_id: self_and_ancestor_ids)
    else
      true
    end
  end

  def set_accessibility!(accessible)
    if !(content_class <= Section)
      errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.can_only_set_accessibility_on_sections'))
      false
    elsif self.is_global_frontpage? || self.contains_global_frontpage?
      errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.cant_make_node_public_when_it_has_a_private_ancestor'))
      false
    elsif !accessible
      update_attribute(:private, true) unless self.private? || self.has_private_ancestor?
      true
    elsif self.has_private_ancestor?
      errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.cant_make_node_public_when_it_has_a_private_ancestor'))
      false
    elsif self.private?
      update_attribute(:private, false)
      true
    else
      true
    end
  rescue
    errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.set_accessibility_failed'))
    false
  end

  def set_visibility!(visible)
    if self.is_global_frontpage? || self.contains_global_frontpage?
      errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.cant_make_node_public_when_it_has_a_private_ancestor'))
      false
    elsif !visible
      Node.update_all('hidden = true', subtree_conditions) unless self.hidden?
      self.hidden = true
      true
    elsif self.has_hidden_ancestor?
      errors.add(:base, I18n.t('activerecord.errors.models.node.attributes.base.cant_make_node_visible_when_it_has_a_hidden_ancestor'))
      false
    else
      Node.update_all('hidden = false', subtree_conditions) if self.hidden?
      self.hidden = false
      true
    end
  rescue
    errors.add(I18n.t('activerecord.errors.models.node.attributes.base.set_visibility_failed'))
    false
  end
end
