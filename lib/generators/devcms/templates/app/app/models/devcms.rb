extension_of DevcmsCore

class Devcms
  class << self
    # Override the content type configuration if needed
    # Example:
    # { 'Calendar' => { :allowed_child_content_types => %w( CalendarItem CombinedMeeting Meeting ) },
    #    'PermitArchive' => { :has_import => true } }

    # def content_types_configuration
    #   {}
    # end

    # Returns a hash representing this node's config properties for an Ext.dvtr.AsyncTreeNode javascript object.
    # The hash returned will be reverse merged with node.to_tree_node_for(user)

    # def tree_node_for(node, user, options = {})
    #   {}
    # end

    # def search_configuration
    #   {
    #     :enabled_search_engines => ['ferret'],
    #     :default_search_engine => 'ferret',
    #     :default_page_size => Settler[:search_default_page_size].to_i,
    #     :ferret => {
    #       :synonym_weight => Settler[:search_ferret_synonym_weight].to_f,
    #       :proximity => Settler[:search_ferret_proximity].to_f
    #     }
    #   }
    # end

    # def content_box_colours
    #   %w( default )
    # end

    # def content_box_icons
    #   %w( )
    # end

    # def reserved_logins_regex
    #   /(burger?meester|wethouder|gemeente|stads|student|leerling|voorlichting|communicatie|openba?are?|brandweer|politie|ambulance|ggz|ggd|ziekenhuis|school|hospitaal|gemeente|college|stadhuis)/i
    # end

    # def node_locales
    #   {
    #     "Nederlands" => "nl",
    #     "Engels"     => "en",
    #     "Duits"      => "de",
    #     "Spaans"     => "es",
    #     "Frans"      => "fr"
    #   }
    # end
  end
end
