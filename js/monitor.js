var Monitor =
{
  AJAX_REQUEST_LTIMEOUT: 180000,   // milliseconds
     autoUpdateInterval: 1200000,  // milliseconds
      autoUpdateTimerID: null,
                    msg: '',
                tabList: new Array('summary', 'dataset', 'requester', 'group', 'quicksearch')
};
Monitor.baseURL = function () {
  var url = location.protocol + '//' + location.host;
  return url;
};
Monitor.BASE_URL = Monitor.baseURL() + '/phedex';
Monitor.addRandom = function (url) {
  return (url + '?t='+Math.random());
};
Monitor.startAutoUpdate = function() {
  Monitor.autoUpdateTimerID 
    = setInterval('Monitor.requestSiteInfo()', Monitor.autoUpdateInterval);
};
Monitor.stopAutoUpdate = function() {
  if (Monitor.autoUpdateTimerID != null) {
    clearInterval(Monitor.autoUpdateTimerID); 
    Monitor.autoUpdateTimerID = null;
  }
};
Monitor.toggleAutoUpdate = function() {
  ($('#check-autoupdate').attr('checked')) ? Monitor.startAutoUpdate()
                                           : Monitor.stopAutoUpdate(); 
};
Monitor.getSelectedValue = function (id) {
  return $('#' + id + ' option:selected').val();
}
Monitor.clearSelectBox = function (id) {
  $('#' + id + ' option').each(function() {
    $(this).remove();
  });
};
Monitor.referTo = function(obj, tabId, tabIndex) 
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
};
Monitor.addClass = function(obj, clist) 
{
  var list = $(obj).contents().filter(function() { return obj.nodeType == 1; });
  var len = list.length;
  for (var i = 0; i < len; ++i) {
    var obj = list[i];
    $(obj).addClass(clist[i]);
  }
};
Monitor.dressUp = function() 
{
  $('div.panel-header').hide();
  $('div#panel-timestamp').html($('div.panel-header').html());
  $('div.panel-footer').hide();
  $('#tab-a1,#tab-a2,#tab-a3,#tab-a4,#tab-a5')
    .css('height', '588px')  // Note the height set
    .css('overflow','auto');
  $('div.dataset > div > a').addClass('button');
  $('h2').addClass('ui-corner-all')
         .css('color', '#000')
         .addClass('ui-default-state');

  // set colors property
  $('span.green').css('color', 'green');
  $('span.grey').css('color', 'grey');
  $('span.red').css('color', 'red');

  // table elements
  $('table > tfoot').css('font-weight','bold');
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
      Monitor.referTo(this, 'div#tab-a4', 3);
    });
  });

  // Must consider that there are many many tables
  // so should anchor correctly at tbody
  var arr = ['requester', 'group'];
  var ac = new Array('dset', 'dreq', 'dsize', 'dtime');
  jQuery.each(arr, function() {
    $('div.' + this + ' > table tr').each(function () {
      Monitor.addClass(this, ac);
    });
    $('div.' + this + ' > table > tbody > tr > td').filter('.dset').dblclick(function() {
      Monitor.referTo(this, 'div#tab-a2', 1);
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
                    header: 'ui-icon-circle-arrow-e',
            headerSelected: 'ui-icon-circle-arrow-s'
          }
  });
  var clist = new Array('dset', 'deml', 'dgrp', 'dsize', 'dtime');
  $('table#searchable tr').each(function () {
    Monitor.addClass(this, clist);
  });
  $('table#searchable > tbody > tr > td').filter('.dset').dblclick(function() {
    Monitor.referTo(this, 'div#tab-a2', 1);
  });
  $('input#id_search').quicksearch('table#searchable tbody tr',
  {
          delay: 100,
     stripeRows: ['odd', 'even'],
       'loader': 'span.loading'
  });
  // make the table sortables
  forEach(document.getElementsByTagName('table'), function(table) {
    if (table.className.search(/\bsortable\b/) != -1) {
      sorttable.makeSortable(table);
    }
  });
};
Monitor.findItem = function(id, name) {
  var obj = $('#' + id).get(0);
  if (obj == null) {
    alert('Failed to find the' + id + ' Object!');
    return false;
  }
  var index = -1;
  obj.selectedIndex = index;
  var len = obj.length;
  for (var i = 0; i < len; i++) {
    var val = obj.options[i].value;
    if (val == name) {
      index = i;
      break;
    }
  }
  if (index < 0) return false;

  obj.selectedIndex = index;
  return true;
};
Monitor.fillSiteList = function() 
{
  var check_params = false;
  var args = arguments[0]; 
  if (args != null && args > 0) check_params = true;

  Monitor.clearSelectBox('select-site');
  var tclass = $('input:radio[name=tclass]:checked').val();
  if (check_params && $(document).getUrlParam('site') != null) {
    var site = $(document).getUrlParam('site');
    var tag = site.split('_')[0];
    if (tclass != tag) {
      var obj = "input:radio[value=" + tag + "]'";
      $(obj).attr('checked', true);
      tclass = $('input:radio[name=tclass]:checked').val();
    }
  }

  var url = Monitor.BASE_URL + '/sites.json';
  Monitor.msg = '<h2 style="color:#fff;"><img src="images/wait.gif" /> Loading site list, please wait ...</h2>';
  jQuery.getJSON(Monitor.addRandom(url), function(data) {
    var obj = $('#select-site').get(0);
    var items = data.items;
    jQuery.each(items, function() {
      var name = this;
      if (name.indexOf(tclass) > -1) {
        var option = new Option(name, name);
        option.title = name;
        try {
          obj.add(option, null);
        }
        catch (e) {
          obj.add(option, -1);
        }
      }
    });
    if (!check_params) return;

    // now check if any parameter was passed
    if ($(document).getUrlParam('autoupdate') != null) {
      var au = $(document).getUrlParam('autoupdate');
      if (au == 'true' || au == '1') 
        $('#check-autoupdate').attr('checked', 'true');
    }
    if ($(document).getUrlParam('site') != null) {
      var site = $(document).getUrlParam('site');
      if (Monitor.findItem('select-site', site)) 
        setTimeout('Monitor.requestSiteInfo()', 100); // millisec
    }
  });
};
Monitor.errorResponse = function (transport, status, errorThrown) {
  var message = 'Last Ajax request failed, ' + 'status=' + status;
  if (status != 'timeout') message += "\nServer says:\n" + transport.responseText;
  alert(message);

  // re-install autoupdate in any case
  if ($('#check-autoupdate').attr('checked')) Monitor.startAutoUpdate()
};
Monitor.loadResponse = function(response, status) 
{
  $('#tabview-panel').empty();
  // do _not_ remove the next 2 lines
  // response = $(response).not('style, meta, link, script, title');
  // $('#tabview-panel').append(response);
  $('#tabview-panel').append(response.replace("<head>", "<!-- <head>").replace("</head>", "</head> -->"));
  Monitor.dressUp();

  // now show the requested tab
  var tabIndex = 0;
  if ($(document).getUrlParam('tab') != null) {
    var tabname = $(document).getUrlParam('tab');
    tabIndex = jQuery.inArray(tabname.toLowerCase(), Monitor.tabList); 
    if (tabIndex < 0) tabIndex = 0;
  }
  $('#tabpanel').tabs('option', 'selected', tabIndex);
  
  $('div#panel-timestamp').fadeTo('slow', 1.0);
  $('#tabview-panel').fadeTo('fast', 1.0);
  $('#tabpanel').css('border','0px solid #aed0ea');

  // re-install autoupdate
  if ($('#check-autoupdate').attr('checked')) Monitor.startAutoUpdate()
}

Monitor.setMessage = function(e) 
{
  Monitor.msg = '<h2 style="color:#fff;"><img src="images/wait.gif" /> Loading help, please wait ...</h2>';
  return true;
}
// this function is invoked when the RRD file name changes
Monitor.requestSiteInfo = function() 
{
  // Irrespective of conitions uninstall AutoUpdate
  Monitor.stopAutoUpdate();

  var site = Monitor.getSelectedValue('select-site');
  var url = Monitor.BASE_URL + '/' + site + '.html';
  Monitor.msg = '<h2 style="color:#fff;"><img src="images/wait.gif" /> Loading information for ' + site + '...</h2>';
  var transport = $.ajax({
           url: url, 
         cache: false,
          type: 'GET',
         async: true,
      dataType: 'html',
       timeout: Monitor.AJAX_REQUEST_LTIMEOUT,
       success: Monitor.loadResponse,
         error: Monitor.errorResponse
  });
  $('div#panel-timestamp').fadeTo('slow', 0.1);
  $('#tabview-panel').fadeTo('slow', 0.1);
};
// input field's event handlers
// wait till the DOM is loaded
$(document).ready(function() {
  $('body').css('font-size','0.75em');
  $('body,span,div,a,p,label,textarea,fieldset').addClass('ui-widget');
  $('textarea,fieldset,p').addClass('ui-widget-content');
  $('div,fieldset').addClass('ui-corner-all');
  $('div.panel').addClass('ui-default-state');
  $('div.h-panel').addClass('ui-widget-header');
  $('select').css('width', '120px');
  $('select#select-site').css('width', '180px');
  $('#content-panel').css('border','1px solid #aed0ea');

  // Buttons
  $('input:submit[value=Show]').click(Monitor.requestSiteInfo);

  // Checkbox
  $('#check-autoupdate').click(Monitor.toggleAutoUpdate);
  $('#check-autoupdate').attr('checked', false);

  // Radio buttons
  $('input:radio[name=tclass]').click(function() {
    setTimeout('Monitor.fillSiteList()', 50); // millisec
  });
  $('input:radio[value=T2]').attr('checked', true);

  $('a.htips').each(function(index) {
    $(this).cluetip({
              width: '400px', 
             height: '300px',
             sticky: true, 
      closePosition: 'title', 
             arrows: true, 
          showTitle: true,
         activation: 'click',
        hoverIntent: {
          sensitivity:   1,
             interval: 750,
              timeout: 750    
        },
                 fx: {             
                   open:       'fadeIn', // can be 'show' or 'slideDown' or 'fadeIn'
                   openSpeed:  'normal'
                 },
        onActivate: Monitor.setMessage,
         ajaxCache: false
    });
  })
  // show/hide the progress panel as soon as ajax request starts/returns
  $('#control-panel').ajaxStart(function() {
    $(this).unblock({fadeOut:0}).block({
         message: null,
      overlayCSS: {
        backgroundColor: '#000',
                opacity: '0.025'
      }
    });
  });
  $('#content-panel').ajaxStart(function() {
    $(this).unblock({fadeOut:0}).block({
      message: Monitor.msg,
          css: { 
                padding: 0, 
                 margin: 0, 
                  width: '40%', 
                    top: '40%', 
                   left: '35%', 
                opacity: '0.6',
              textAlign: 'center', 
                  color: '#f00', 
                 border: '3px solid #aaa', 
        backgroundColor: '#000', 
                 cursor: 'wait' 
      }, 
      overlayCSS: {
        backgroundColor: '#000',
                opacity: '0.025'
      }
    });
  });
  $('#control-panel').ajaxStop(function() {
    $(this).unblock({fadeOut: 0});
  });
  $('#content-panel').ajaxStop(function() {
    $(this).unblock({fadeOut: 1000});
  });
  setTimeout('Monitor.fillSiteList(1)', 50); // millisec
});
