$(document).ready(function() {
  //whatever you would like to do to the form here
  // Change function
  function toggleVisibility(){
    if (jQuery.inArray($('#workflow_statuses').val(),['2', '4']) != -1){
      //alert("show")
      $('#workflow_third_party_id_field').show();
    }else{
      //alert('hide')
      $('#workflow_third_party_id_field').hide();
    }
  }

  $('#workflow_statuses').change(function(e){
    // alert($('#workflow_statuses').val())
    toggleVisibility();
  });

  toggleVisibility();
});