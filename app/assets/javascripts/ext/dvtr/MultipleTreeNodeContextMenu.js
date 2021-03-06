/**
 * @class Ext.dvtr.MultipleTreeNodeContextMenu
 * @extends Ext.menu.Menu
 */

Ext.dvtr.MultipleTreeNodeContextMenu = Ext.extend(Ext.menu.Menu, {
  show: function (anchorNode, selectedNodes) {
    this.selectedNodes = selectedNodes;

    this.addButtons();

    if (this.items.getCount() > 0) {
      Ext.dvtr.TreeNodeContextMenu.superclass.show.call(this, anchorNode.getUI().getAnchor());
    }
  },

  addButtons: function () {
    this.addEditButton();
  },

  addEditButton: function () {
    var allNodesAreEditable = true;

    this.selectedNodes.each(function (node) {
      if (!node.isEditable()) {
        allNodesAreEditable = false;
      }
    }, this);

    if (allNodesAreEditable) {
      this.add({
        text: I18n.t('edit', 'generic'),
        icon: '/images/icons/pencil.png',
        handler: this.handleEdit.createDelegate(this)
      });
    }
  },

  // Button handlers

  handleEdit: function () {
    var nodeIDs = [];

    this.selectedNodes.each(function (node) {
      nodeIDs.push(node.id);
    });

    rightPanel.load({
      url: '/admin/nodes/bulk_edit',
      params: Ext.ux.prepareParams(defaultParams, { format: 'html', 'ids[]': nodeIDs }),
      method: 'GET',
      callback: function (options, success, response) {
        if (!success) {
          Ext.ux.alertResponseError(response, I18n.t('form_load_failed', 'errors'));
        }
      }
    });
  }
});
