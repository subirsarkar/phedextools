var Page = {
  referTo: function(obj, tabId, tabIndex) 
  {
    // Get hold of the datasets in an array and find the index
    var elements = jQuery.makeArray($(tabId + ' .accordion h3 a'));
    var arr = jQuery.map(elements, function (el) { 
      var a = $(el).html().split(/\s+/); // multiple spaces allowed
      return a[0];
    });
    if (!arr.length) return;

    // now find the selected value and find the index in the above array
    var dset = $(obj).html();
    var index = jQuery.inArray(dset, arr); 

    // go back to the dataset tab and then expand the selected dataset
    if (index > -1) {
      $('#tabpanel').tabs('option', 'selected', tabIndex);
      $(tabId + ' .accordion').accordion('activate', index);
      var el = elements[index];
      $(el).focus();
    }
  },
  addClass: function(obj, clist) 
  {
    var list = $(obj).contents().filter(function() { return obj.nodeType == 1; });
    var len = list.length;
    for (var i = 0; i < len; ++i) {
      var obj = list[i];
      $(obj).addClass(clist[i]);
    }
  }
};
$(document).ready(function() 
{
  $('body').css('font-size','0.75em');
  $('body,div,span,a,p,label,select,input,checkbox,radiobutton,button,textarea')
     .addClass('ui-widget');
  $('select,textarea,fieldset,p').addClass('ui-widget-content');
  $('div,fieldset').addClass('ui-corner-all');
  $('input,checkbox,radiobutton,button')
   .addClass('ui-widget-content')
   .addClass('ui-state-default');
  $('h2').addClass('ui-default-state')
         .addClass('ui-corner-all')
         .css('color', '#000');
  $('div.panel-header')
    .addClass('ui-widget-header')
    .css('margin-top','4px');
  $('div.panel-footer')
    .addClass('ui-widget-header')
    .css('margin-top','4px');
  $('div.dataset > div > a').addClass('button');

  // table elements
  $('div.dataset > table').css('width', '80%');
  $('td > div').css('width','100%').css('overflow', 'auto');
  $('div.dataset > div').css('padding', '10px 0px').attr('align','center');
  $('table.sitesummary > tbody > tr > th').css('width', '40%').css('padding', '4px 0px');
  $('table.groupusage > tbody > tr > td').css('padding', '4px 2px');
  $('table.groupusage > thead > tr,\
     table.groupusage > tbody > tr,\
     table.groupusage > tfoot > tr').each(function(i) {
    var el = (i == 0) ? 'th' : 'td';
    $(this).children(el).each(function(index) {
      var a = 'auto';
      if (index == 0) a = '140px';
      else if (index == 1 || index == 3) a = '90px';
      $(this).css('text-align', (index == 0) ? 'center' : 'right')
             .css('width', a);
    });
  });
  $('table.groupusage > tbody > tr').each(function() {
    $(this).children('td').eq(0).dblclick(function() {
      Page.referTo(this, 'div#tab-a4', 3);
    });
  });

  // Must consider that there are many many tables
  // so should anchor correctly at tbody
  var arr = [ 'requester', 'group'];
  var ac = new Array('dset', 'dreq', 'dsize', 'dtime');
  jQuery.each(arr, function() {
    $('div.' + this + ' > table tr').each(function () {
      Page.addClass(this, ac);
    });
    $('div.' + this + ' > table > tbody > tr > td').filter('.dset').dblclick(function() {
      Page.referTo(this, 'div#tab-a2', 1);
    });
  });
  $('#tabpanel').tabs({ selected: 0 });
  $('#tabpanel span').css('font-weight', 'normal');
  $('h3 > a').attr('href', '#');
  $('div.accordion').accordion({
    collapsible: true,
         active: true,
      fillSpace: false,
     autoHeight: false,
       animated: false,
          icons: {
                    header: "ui-icon-circle-arrow-e",
            headerSelected: "ui-icon-circle-arrow-s"
     }
  });
  var clist = new Array('dset', 'deml', 'dgrp', 'dsize', 'dtime');
  $('table#searchable tr').each(function () {
    Page.addClass(this, clist);
  });
  $('table#searchable > tbody > tr > td').filter('.dset').dblclick(function() {
    Page.referTo(this, 'div#tab-a2', 1);
  });
  $('table#searchable tbody tr').quicksearch({
          position: 'before',
          attached: 'table#searchable',
    stripeRowClass: ['odd', 'even'],
         labelText: 'Quick Search:',
        inputClass: 'searchInput',
         inputText: 'type a search string'
  });
});
