class AddCustomTypeToContentRepresentations < ActiveRecord::Migration
  class ContentRepresentation < ActiveRecord::Base
    acts_as_list scope: :parent_id
    belongs_to :parent, class_name: 'Node'
  end

  def self.up
    add_column :content_representations, :custom_type, :string
    change_column :content_representations, :content_id, :integer, null: true, references: :nodes, on_delete: :cascade

    ContentRepresentation.reset_column_information

    count = ContentRepresentation.count
    diff = ContentRepresentation.count(conditions: "content_representations.target = 'secondary_column'", group: :parent_id).keys.size + ContentRepresentation.count(conditions: "content_representations.target = 'primary_column'", group: :parent_id).keys.size * 2

    if Node.unscoped.count > 0
      # Set default own content box placements
      Node.all(include: :content_representations, conditions: "content_representations.target = 'secondary_column' AND content_representations.id IS NOT NULL").each do |node|
        rep = ContentRepresentation.create! parent: node, custom_type: 'related_content', target: 'secondary_column'
        rep.insert_at!(2)
      end

      Node.all(include: :content_representations, conditions: "content_representations.target = 'primary_column' AND content_representations.id IS NOT NULL").each do |node|
        rep = ContentRepresentation.create! parent: node, custom_type: 'sub_menu', target: 'primary_column'
        rep.insert_at!(1)
        rep = ContentRepresentation.create! parent: node, custom_type: 'private_menu', target: 'primary_column'
        rep.insert_at!(2)
      end
    end

    raise "Failed, created #{ContentRepresentation.count - count} boxes. Expected #{diff}" unless ContentRepresentation.count == count + diff
  end

  def self.down
    ContentRepresentations.delete_all('custom_type IS NOT NULL')

    remove_column :content_representations, :custom_type
    change_column :content_representations, :content_id, :integer, null: false, references: :nodes, on_delete: :cascade
  end
end
