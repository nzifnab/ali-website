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
    window.table = table;

    $(".js-order-filter-buttons input[type=button]").on('click', function(e) {
      e.preventDefault();
      var currentVal = $(this).data("active");
      var newVal = !currentVal;

      $(".js-order-filter-buttons input[type=button]").
        addClass("btn-secondary").
        removeClass("btn-primary").
        data("active", false);

      if(newVal) {
        $(this).addClass("btn-primary").
          removeClass("btn-secondary")
      }
      $(this).data("active", newVal);

      if(newVal){
        table.column($(this).data("filter-column")).search($(this).data("filter-value"), true).draw();
      } else {
        table.column($(this).data("filter-column")).search("").draw();
      }
    });

    $("input[data-price]").on("change", function(e) {
      quantity = Number($(this).val());
      quantity ||= 0;

      prices[$(this).data("item")] = Number($(this).data("price")) * quantity;
      calculateTotal();
    });
    calculateTotal();

    $(".js-order-form").on("keydown", function(e){
      return e.key != "Enter";
    });

    $(".js-order-form").on("submit", function(e){
      table.search("").columns().search("").draw();
    });

    $("[data-toggle]").tooltip();

    clipboard = new ClipboardJS("[data-clipboard-target]");
    clipboard.on("success", function(e) {
      $(e.trigger).tooltip({title: "Copied!"});
      $(e.trigger).tooltip("enable");
      $(e.trigger).tooltip("show");

      setTimeout(function(){
        $(e.trigger).tooltip("hide");
        $(e.trigger).tooltip("disable");
      }, 1000);
    });



    $(".js-review-order").on("show.bs.modal", function(e){
      table.search("").columns().search("").draw();
      $(".js-review-order-body").html("");
      $(".js-modal-stock-warning").hide();
      total = 0;
      stockMissing = false;

      $(".js-item-quantity").each(function(){
        $quantityField = $(this)
        quantity = Number($quantityField.val());
        if(!quantity || quantity <= 0){
          return true;
        }

        item = $quantityField.data("item")
        price = $quantityField.data("price")
        stock = $quantityField.data("stock")
        subtotal = quantity * price;

        inStock = (stock >= quantity);
        console.log("stockMissing: " + stockMissing + ", inStock: " + inStock);
        stockMissing ||= !inStock;

        $htmlLine = $(`
          <tr>
            <td>${item}</td>
            <td>${formatMoney(price)}</td>
            <td>${formatMoney(quantity, 0, "")}</td>
            <td>${formatMoney(subtotal, 0)}</td>
            <td>${inStock ? 'Yes' : 'NO'}</td>
          </tr>
        `);

        $(".js-review-order-body").append($htmlLine);

        total += subtotal;
      });

      $(".js-modal-total").html(formatMoney(total, 0));
      if(stockMissing){
        $(".js-modal-stock-warning").show();
      }
    });
  });
})(jQuery);

var prices = {};
function calculateTotal() {
  total = 0;
  Object.entries(prices).forEach(pricing => {
    const [item, price] = pricing;
    total += price;
  })

  $(".js-total-price").text(formatMoney(total, 0));
}

function formatMoney(amount, decimalCount = 2, unit = "Ƶ", decimal = ".", thousands = ",") {
  try {
    decimalCount = Math.abs(decimalCount);
    decimalCount = isNaN(decimalCount) ? 2 : decimalCount;

    const negativeSign = amount < 0 ? "-" : "";

    let i = parseInt(amount = Math.abs(Number(amount) || 0).toFixed(decimalCount)).toString();
    let j = (i.length > 3) ? i.length % 3 : 0;

    return negativeSign + unit + (j ? i.substr(0, j) + thousands : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousands) + (decimalCount ? decimal + Math.abs(amount - i).toFixed(decimalCount).slice(2) : "");
  } catch (e) {
    console.log(e)
  }
};
