(function($){
  $(function(){
    var table = $(".js-order-table").DataTable({
      paging: false,
      columnDefs: [
        {
          targets: "js-no-sort",
          orderable: false
        }, {
          targets: "js-numeric-sort",
          data: function ( row, type, val, meta ) {
            if (type === 'set') {
              console.log("val = " + val);
              row.price = val.replace(/[^0-9\.]/g, "");
              row.price_display = val;
              // Store the computed display and filter values for efficiency
              return;
            }
            else if (type !== 'display') {
              return Number(row.price);
            }
            return row.price_display;
          }
        }
      ]
    });

    $(".js-order-filter-buttons button").on('click', function(e) {
      e.preventDefault();
      var currentVal = $(this).data("active");
      var newVal = !currentVal;

      $(".js-order-filter-buttons button").data("active", false);
      $(this).data("active", newVal);

      if(newVal){
        table.column($(this).data("filter-column")).search($(this).data("filter-value"), true);
      }
    });
  });
})(jQuery);
