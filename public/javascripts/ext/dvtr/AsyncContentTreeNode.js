/**
 * @class Ext.dvtr.AsyncContentTreeNode
 * @extends Ext.tree.AsyncTreeNode
 */

Ext.dvtr.AsyncContentTreeNode = function(config) {
   Ext.COPY_INDICATOR_PATH = '/images/icons/copy_indicator.gif';
   Ext.GLOBAL_FRONTPAGE_INDICATOR_PATH = '/images/icons/frontpage_indicator.gif';
   Ext.GLOBAL_FRONTPAGE_AND_COPY_INDICATOR_PATH = '/images/icons/frontpage_and_copy_indicator.gif';

   // Read out configuration object, and make changes before passing it through to superclass constructor.
   if (config) {
       if (config.isGlobalFrontpage) {
          if (config.isContentCopy) {
            config.icon = Ext.GLOBAL_FRONTPAGE_AND_COPY_INDICATOR_PATH;
          } else {
            config.icon = Ext.GLOBAL_FRONTPAGE_INDICATOR_PATH;
          }

          Ext.dvtr.AsyncContentTreeNode.current_global_frontpage_node = this;
       } else if (config.isContentCopy) {
         config.icon = Ext.COPY_INDICATOR_PATH;
       }

       if (config.isPrivate || config.hasPrivateAncestor){
         config.cls = 'hiddenNode';
       }

       this.ownContentType = config.ownContentType;
       this.siteNodeId = config.siteNodeId
       this.allowedChildContentTypes = config.allowedChildContentTypes;

       this.hasPrivateAncestor = config.hasPrivateAncestor;
       this.baseParams = config.baseParams;
       this.isRoot = config.isRoot;
       this.isContentCopy = config.isContentCopy;
       this.isRepeatingCalendarItem = config.isRepeatingCalendarItem;
       this.isFrontpage = config.isFrontpage;
       this.isGlobalFrontpage = config.isGlobalFrontpage;
       this.containsGlobalFrontpage = config.containsGlobalFrontpage;
       this.userRole = config.userRole;
       this.urlAlias = config.urlAlias;
       this.noChildNodes = config.noChildNodes;
       this.numberChildren = config.numberChildren;
       this.isPrivate = config.isPrivate;
       this.category = config.category;
       this.hasImport = config.hasImport;
       this.hasSync = config.hasSync;
       this.hasEditItems = config.hasEditItems;
			 this.availableContentRepresentations = config.availableContentRepresentations;

       /* permissions */
       this.undeletable = config.undeletable
       this.allowGlobalFrontpageSetting = config.allowGlobalFrontpageSetting
       this.allowTogglePrivate = config.allowTogglePrivate
       this.allowToggleChangedFeed = config.allowToggleChangedFeed
       this.allowUrlAliasSetting = config.allowUrlAliasSetting
       this.allowContentCopyCreation = config.allowContentCopyCreation
       this.allowRoleAssignment = config.allowRoleAssignment
       this.allowSortChildren = config.allowSortChildren
       this.allowLayoutConfig = config.allowLayoutConfig
       this.initialChildCount = config.childCount

       // Save initial text for re-use
       this.originalText = config.text;
   }

   Ext.dvtr.AsyncContentTreeNode.superclass.constructor.call(this, config);

   // Make sure child nodes can be appended to this node even if it was a leaf initially.
   this.isTargetEvenIfLeaf = true;

   // This flag is set to true if this.initialChildCount becomes stale.
   this.childCountChanged = false;

   /*** Private functions ***/

   this.constructMenu = function() {
       // Create and assign a new context menu
       if (this.userHasRole()) {
         this.contextMenu = new Ext.dvtr.TreeNodeContextMenu({tn: this});
       }
   };

   this.constructMenu(true);

   this.constructText = function() {
        var txt = this.originalText;
        if(this.isPrivate) { txt += ' (priv&eacute;)'; }
        return txt;
   };

   this.renumberChildren = function() {
      Ext.each(this.childNodes, function(tn, i){
        tn.setText((i+1) + '. ' + this.constructText());
      });
   };

   /**
   * Reconstructs the menu, resets the text label and reloads its children or, if not expanded
   * makes sure a reload is triggered when de children are expanded.
   */
   this.reset = function(){
        this.constructMenu();
        this.setText(this.constructText());
        if(this.parentNode && this.parentNode.numberChildren) { this.parentNode.renumberChildren(); }
        if(this.expanded){
          this.reload();
        }else{
          this.loaded = false;
        }
   };

   this.makePrivate = function(){
        this.isPrivate = true;
        this.getUI().addClass('hiddenNode'); // Doesnt work on initialize, therefore its style is set through the config object as well.
        this.reset();
   };
   this.makePublic = function(){
        this.isPrivate = false;
        this.getUI().removeClass('hiddenNode');
        this.reset();
   };

   // Initialize as private if is private
   if(this.isPrivate){
       this.makePrivate();
   }

   // Add listeners:
   this.on('beforeMove', this.onBeforeMove);
   this.on('move', this.onMove);
   this.on('dblclick', this.onShow);

   Ext.each(['insert','append','remove'], function(event){
      this.on(event, function(t,n){
          n.childCountChanged = true;
          n.constructMenu();
      });
   }, this);

   if(this.numberChildren) { this.on('beforechildrenrendered', this.renumberChildren, this); }
};
// Extend the original TreeLoader class
Ext.extend(Ext.dvtr.AsyncContentTreeNode, Ext.tree.AsyncTreeNode,{
    isEditable: function() {
        return this.userHasRole() && this.attributes.allowEdit;
    },

    hasChildNodes: function(){
        return  !this.leaf && ((this.loaded && this.childNodes.length > 0) || !this.noChildNodes);
    },

    userHasRole: function(){
        return this.userRole ? true : false;
    },

    onContextmenu: function(){
        this.contextMenu.show();
    },

    onShow: function(){

        rightPanel.load({
            url: this.attributes.controllerName+'/show/'+this.attributes.contentNodeId,
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success) {
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });

        return false; // prevents toggling of childnodes.
    },

    onBeforeMove: function(tree, node, oldParent, newParent, index) {
      return newParent.allowedChildContentTypes.indexOf(this.ownContentType) != -1;
    }, // end onBeforeMove

    onMove: function(tree, node, oldParent, newParent, index){
      /* renumber if necessary */
      Ext.each([oldParent, newParent], function(prt){
        if(prt.numberChildren) { prt.renumberChildren(); }
      });

      /* post ajax request */
      if (this.nextSibling) {
        var customParams = {next_sibling: this.nextSibling.id};
      } else {
        var customParams = {parent: newParent.id};
      }

      Ext.Ajax.request({
        url: '/admin/nodes/' + this.id + '/move',
        method: 'POST', // overridden with put by the _method parameter
        params: Ext.ux.prepareParams(this.baseParams, Ext.apply(customParams, {_method: 'put'})),
        scope: this,
        failure: function(response, options){
          Ext.ux.alertResponseError(response, I18n.t('move_failed', 'nodes'), false);
          // reset structure:
          this.remove(); // remove node from its old parent
          oldParent.reload(); // reload its old parent
        },
        success: function(response, options) {
           newParent.leaf = false;
           newParent.renderIndent();

           // Reconstruct menus as options may have changed due to a new children count, like sorting.
           oldParent.constructMenu();
           newParent.constructMenu();
        }
      });
    },// end onMove

    onDelete: function(){
      this.ui.addClass('x-tree-node-loading');
      Ext.Ajax.request({
         url: '/admin/nodes/'+this.id,
         method: 'POST', // overridden with delete by the _method parameter
         params: Ext.ux.prepareParams(this.baseParams, {_method: 'delete'}),
         scope: this,
         success: function(){
             var parent = this.parentNode;
             this.remove();
             parent.renderIndent();
             if(parent.numberChildren) { parent.renumberChildren(); }

             // Reconstruct menu as options may have changed due to a new children count, like sorting.
             this.constructMenu();
         },
         failure: function(response, options){
            this.ui.removeClass('x-tree-node-loading');
            Ext.ux.alertResponseError(response, I18n.t('delete_failed', 'nodes'));
         }
      });
    },

    onRepeatingCalendarItemDelete: function() {
      this.ui.addClass('x-tree-node-loading');
      Ext.Ajax.request({
         url: '/admin/calendar_items/'+this.attributes.contentNodeId,
         method: 'POST', // overridden with delete by the _method parameter
         params: Ext.ux.prepareParams(this.baseParams, {_method: 'delete'}),
         scope: this,
         success: function() {
           this.parentNode.parentNode.reload();
         },
         failure: function(response, options){
           this.ui.removeClass('x-tree-node-loading');
           Ext.ux.alertResponseError(response, I18n.t('delete_failed', 'calendar_items'));
         }
      });
    },

    onEdit: function(){
        rightPanel.load({
            url: this.attributes.controllerName+'/'+this.attributes.contentNodeId+'/edit',
            scripts: true,
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success) {
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
    },

    onEditItems: function(){
        rightPanel.load({
            url: this.attributes.controllerName+'/'+this.attributes.contentNodeId+'/edit_items',
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success) {
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
    },

	onAbbreviations: function(){
		rightPanel.load({
			url: '/admin/abbreviations/',
			params: Ext.ux.prepareParams(defaultParams, {node_id: this.attributes.id, format: 'html'}),
			method: 'GET',
			callback: function(options, success, response) {
				if(!success) {
					Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
				}
			}
		});
	},

	onSynonyms: function(){
		rightPanel.load({
			url: '/admin/synonyms/',
			params: Ext.ux.prepareParams(defaultParams, {node_id: this.attributes.id, format: 'html'}),
			method: 'GET',
			callback: function(options, success, response) {
				if(!success) {
					Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
				}
			}
		});
	},

    onImport: function(){
        rightPanel.load({
            url: this.attributes.controllerName+'/'+this.attributes.contentNodeId+'/import',
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success) {
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
    },
    
    onSync: function(){
        rightPanel.load({
            url: this.attributes.controllerName+'/'+this.attributes.contentNodeId+'/sync',
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success) {
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
    },
    
    onInsertNew: function(contentType){
        rightPanel.load({
            url: contentType.controllerName+'/new',
            params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.id, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success){
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
    },

    onSetGlobalFrontpage: function() {
        Ext.Ajax.request({
           url: '/admin/nodes/'+this.id+'/make_global_frontpage',
           method: 'POST', // overridden with delete by the _method parameter
           params: Ext.ux.prepareParams(defaultParams, {_method: 'put'}),
           scope: this,
           success: function() {
              if (Ext.dvtr.AsyncContentTreeNode.current_global_frontpage_node) {
                  var prev_fp = Ext.dvtr.AsyncContentTreeNode.current_global_frontpage_node;

                  if (prev_fp.isContentCopy) {
                    prev_fp.ui.getIconEl().src = Ext.COPY_INDICATOR_PATH;
                  } else {
                    prev_fp.ui.getIconEl().src = Ext.BLANK_IMAGE_URL;
                  }

                  prev_fp.isGlobalFrontpage = false;

                  if (!prev_fp.isRoot) {
                    prev_fp.parentNode.SetContainsGlobalFrontpage(false); // Notify parent as it does not contain the global frontpage any longer
                  }

                  prev_fp.constructMenu();
              }

              this.isGlobalFrontpage = true;

              if (!this.isRoot) {
                this.parentNode.SetContainsGlobalFrontpage(true); // Notify parent as it now contains the global frontpage
              }

              Ext.dvtr.AsyncContentTreeNode.current_global_frontpage_node = this;

              this.constructMenu();

              if (this.isContentCopy) {
                this.ui.getIconEl().src = Ext.GLOBAL_FRONTPAGE_AND_COPY_INDICATOR_PATH;
              } else {
                this.ui.getIconEl().src = Ext.GLOBAL_FRONTPAGE_INDICATOR_PATH;
              }

              Ext.Msg.alert('Succes', I18n.t('global_frontpage_success', 'nodes'));
           },
           failure: function(response, options) {
              Ext.ux.alertResponseError(response, I18n.t('global_frontpage_failed', 'nodes'));
           }
        });
    },

    onTogglePrivate: function(item, checked){
       Ext.Ajax.request({
           url: '/admin/nodes/'+this.id,
           method: 'POST', // overridden with delete by the _method parameter
           params: Ext.ux.prepareParams(defaultParams, {_method: 'put', 'node[hidden]': (checked ? '1' : '0')}),
           scope: this,
           success: function() {
              checked ? this.makePrivate() : this.makePublic();
           },
           callback: function(options, success, response) {
                if (!success && response.status == 422) {
                    item.setChecked(!checked, true); // reset checked state
                    var responseJson = Ext.util.JSON.decode(response.responseText);
                    Ext.Msg.alert('Error', responseJson.errors[0] );
                } else if(!success) {
                    item.setChecked(!checked, true); // reset checked state
                    Ext.ux.alertResponseError(response, I18n.t('invisible_failed', 'nodes'));
                }
              }
        });
    },

    onToggleShowInMenu: function(item, checked){
       Ext.Ajax.request({
           url: '/admin/nodes/' + this.id,
           method: 'POST', // overridden with put by the _method parameter
           params: Ext.ux.prepareParams(defaultParams, {_method: 'put', 'node[show_in_menu]': (checked ? '1' : '0')}),
           scope: this,
           callback: function(options, success, response) {
              if (!success && response.status == 422) {
                  item.setChecked(!checked, true); // reset checked state
                  var responseJson = Ext.util.JSON.decode(response.responseText);
                  Ext.Msg.alert('Error', responseJson.errors[0]);
              } else if (!success) {
                  item.setChecked(!checked, true); // reset checked state
                  Ext.ux.alertResponseError(response, I18n.t('show_in_menu_failed', 'nodes'));
              } else if (success) {
                  this.attributes.showInMenu = checked;
                  this.constructMenu();
              }
            }
        });
    },

    onToggleHasChangedFeed: function(item, checked){
       Ext.Ajax.request({
           url: '/admin/nodes/' + this.id,
           method: 'POST', // overridden with put by the _method parameter
           params: Ext.ux.prepareParams(defaultParams, {_method: 'put', 'node[has_changed_feed]': (checked ? '1' : '0')}),
           scope: this,
           callback: function(options, success, response) {
              if (!success && response.status == 422) {
                  item.setChecked(!checked, true); // reset checked state
                  var responseJson = Ext.util.JSON.decode(response.responseText);
                  Ext.Msg.alert('Error', responseJson.errors[0]);
              } else if (!success) {
                  item.setChecked(!checked, true); // reset checked state
                  Ext.ux.alertResponseError(response, I18n.t('change_feed_failed', 'nodes'));
              } else if (success) {
                  this.attributes.hasChangedFeed = checked;
                  this.constructMenu();
              }
            }
        });
    },

    onCreateContentCopy: function() {
      Ext.Ajax.request({
        url: '/admin/content_copies',
        method: 'POST',
        params: Ext.ux.prepareParams(defaultParams, {parent_node_id: this.attributes.parentNodeId, 'content_copy[copied_node_id]': this.id}),
        scope: this,
        success: function(response, options) {
          var responseJson = Ext.util.JSON.decode(response.responseText);
          Ext.Msg.alert('Succes', responseJson.notice);
          this.parentNode.reload();
        },
        failure: function(response, options) {
          if (response.status == 422) { // unprocessable entity
            var responseJson = Ext.util.JSON.decode(response.responseText);
            Ext.Msg.alert('Error', responseJson.errors[0]);
          } else { // unhandled error statuses
            Ext.ux.alertResponseError(response, I18n.t('content_copy_failed', 'nodes'));
          }
        }
      });
    },

    onSetUrlAlias: function(item){
        var promptText = I18n.t('url_alias_prompt', 'nodes');
        if(this.urlAlias) {
            promptText += '<br/>' + I18n.t('url_alias_prompt_current', 'nodes') + ' <i>'+ this.urlAlias +'</i>.';
        }

        Ext.Msg.prompt('Webadres', promptText, function(btn, text){
            if (btn == 'ok'){
               Ext.Ajax.request({
                   url: '/admin/nodes/'+this.id,
                   method: 'POST', // overridden with delete by the _method parameter
                   params: Ext.ux.prepareParams(defaultParams, {_method: 'put', 'node[url_alias]': text}),
                   scope: this,
                   success: function(){
                      this.urlAlias = text;
                      //Ext.Msg.alert('Succes', 'Webadres instellen gelukt!');
                   },
                   failure: function(response, options){
                      if(response.status == 422){ // unprocessable entity
                        var responseJson = Ext.util.JSON.decode(response.responseText);
                        Ext.Msg.alert('Error', responseJson.errors[0]);
                      }else{ // unhandled error statuses
                        Ext.ux.alertResponseError(response, I18n.t('url_alias_failed', 'nodes'));
                      }
                   }
                });
            }
        }, this); // End Ext.Msg.prompt
    },

    onAssignRole: function(){
       rightPanel.load({
            url: '/admin/permissions/new',
            params: Ext.ux.prepareParams(defaultParams, {node_id: this.id, format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success){
                    Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
                }
            }
        });
     },

    onAssignCategory: function(){
        promptText = '';
        node = this;

        if(this.category) {
            promptText += I18n.t('current', 'categories') + ' <i>'+ this.category +'</i>.';
        }
        wnd = new Ext.Window({
            modal: true,
            layout: 'fit',
            height: 135,
            width: 285,
            title: I18n.t('assign_title', 'categories'),
            items: [{
              xtype: 'form',
              itemId: 'category',
              bodyStyle: 'padding:5px',
              items: [{
                  xtype: 'panel',
                  border: false,
                  html: promptText
              },{
                  xtype: 'combo',
                  itemId: 'category_combo',
                  emptyText: I18n.t('choose', 'categories'),
                  fieldLabel: 'Categorie',
                  store: new Ext.data.Store({
                    proxy: new Ext.data.HttpProxy({
                      url: '/admin/categories/categories.json',
                      method: 'GET'
                    }),

                    reader: new Ext.data.JsonReader({
                      root: 'categories',
                      id: 'id',
                      totalProperty: 'total_count'
                    },[ 'id', 'label' ])
                  }),
                  valueField:'id',
                  displayField:'label',
                  forceSelection: true,
                  triggerAction: 'all',
                  editable: false,
                  mode:'remote',
                  width: 150,
                  hiddenName: 'node[category_id]'
              }]
            }],
            buttonAlign: 'center',
            buttons: [{
                  xtype: 'button',
                  text: I18n.t('submit', 'categories'),
                  type: 'submit',
                  handler: function(e){
                      wnd.getComponent('category').getForm().submit({
                          url: '/admin/nodes/' + node.id + '.json',
                          method: 'PUT',
                          failure: function(response, options) {
                            var responseJson = Ext.util.JSON.decode(response.responseText);
                            Ext.Msg.alert('Error', responseJson.errors[0]);
                          },
                          success: function() {
                            var combo = wnd.getComponent('category').getComponent('category_combo');
                            node.category = combo.getRawValue();
                            wnd.close();
                            Ext.Msg.alert(I18n.t('success', 'categories'), I18n.t('element_added_to', 'categories') + ' \'' + node.category + '\'.');
                          }
                      });
                  }
              },{
                  xtype: 'button',
                  text: I18n.t('cancel', 'categories'),
                  type: 'reset',
                  handler: function(e){
                      wnd.close();
                  }
              }]
        });
        wnd.show();
    },

    onLayoutConfig: function(){
        rightPanel.load({
            url: '/admin/nodes/' + this.id + '/layout/edit',
            params: Ext.ux.prepareParams(defaultParams, {format: 'html'}),
            method: 'GET',
            callback: function(options, success, response) {
                if(!success){
                    Ext.ux.alertResponseError(response, I18n.t('page_load_failed', 'errors'));
                }
            }
        });
    },

    onSort: function(sortBy, order){
        this.ui.addClass('x-tree-node-loading');
        this.collapse();

        Ext.Ajax.request({
             url: '/admin/nodes/'+this.id+'/sort_children/',
             method: 'POST', // overridden with delete by the _method parameter
             params: Ext.ux.prepareParams(defaultParams, {_method: 'put', sort_by: sortBy, order: order}),
             scope: this,
             success: function(){
                this.ui.removeClass('x-tree-node-loading');

                // reload children in tree
                this.reload();
             },
             failure: function(response, options){
                this.ui.removeClass('x-tree-node-loading');
                this.expand();
                Ext.ux.alertResponseError(response, I18n.t('sort_failed', 'nodes'));
             }
        });
    },

    SetContainsGlobalFrontpage: function(flag) {
        this.containsGlobalFrontpage = flag;
        this.constructMenu();

        if (!this.isRoot) {
          this.parentNode.SetContainsGlobalFrontpage(flag);
        }
    },

    liveChildCount: function(callback){
        Ext.Ajax.request({
             url: '/admin/nodes/'+this.id+'/count_children',
             method: 'GET',
             params: defaultParams,
             scope: this,
             success: callback,
             failure: function(response, options){
                Ext.ux.alertResponseError(response, I18n.t('error_occurred', 'errors'));
             }
        });
    }
});

/**
 * Override the Ext.tree.TreeDropZone class to work properly with our custom AsyncContentTreeNode class.
 */
Ext.override(Ext.tree.TreeDropZone, {
    getDropPoint : function(e, n, dd) {
        var tn = n.node;
        if(tn.isRoot){
            return tn.allowChildren !== false ? "append" : false; // always append for root
        }
        var dragEl = n.ddel;
        var t = Ext.lib.Dom.getY(dragEl), b = t + dragEl.offsetHeight;
        var y = Ext.lib.Event.getPageY(e);
        // Also check for isTargetEvenIfLeaf property:
        var noAppend = !tn.isTargetEvenIfLeaf && (tn.allowChildren === false || tn.isLeaf());
        if(this.appendOnly || tn.parentNode.allowChildren === false){
            return noAppend ? false : "append";
        }
        var noBelow = false;
        if(!this.allowParentInsert){
            noBelow = tn.hasChildNodes() && tn.isExpanded();
        }
        var q = (b - t) / (noAppend ? 2 : 3);
        if(y >= t && y < (t + q)){
            return "above";
        }else if(!noBelow && (noAppend || y >= b-q && y <= b)){
            return "below";
        }else{
            return "append";
        }
    }
});

/**
 * Override the dbl click behaviour in the  Ext.tree.TreeNodeUI class.
 */
Ext.override(Ext.tree.TreeNodeUI, {
    onDblClick : function(e){
        e.preventDefault();
        if(this.disabled){
            return;
        }
        // If the dblclick handler returns false all default behaviour will be omitted:
        if( this.fireEvent("dblclick", this.node, e) !== false ){
            if(this.checkbox){
                this.toggleCheck();
            }
            if(!this.animating && this.node.hasChildNodes() ){
                this.node.toggle();
            }
        }
    }
});
